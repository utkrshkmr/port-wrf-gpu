#!/usr/bin/env python3
"""Machine detection, profiles and capabilities (phase S0-00; ADR-006 rev 2).

machine.sh collects the raw outputs of the machine into a directory (the same
layout as the recorded samples in port/machines/samples/<profile>/):

  gpus.csv        nvidia-smi --query-gpu=<QUERY> --format=csv
  nvidia-smi.txt  the header of plain nvidia-smi (CUDA version)
  topo.txt        nvidia-smi topo -m
  lscpu.txt       LC_ALL=C lscpu
  meminfo.txt     the MemTotal line of /proc/meminfo
  host.txt        key=value lines machine.sh adds on a live machine: id_source
                  (a hash of /etc/machine-id, never the host name), rapl,
                  container, container_usable, detected_in

This tool parses that directory, derives the capabilities from the numbers
(never from a name), and writes the machine record.

  machine.py detect RAWDIR [--out machine.json]   parse, derive, write, print the profile
  machine.py show [machine.json]                  print the profile of a record
  machine.py get KEY [machine.json]               one value (dotted key) for shell scripts
  machine.py diff OLD.json NEW.json               what changed: same | gpu | host | gpu+host
  machine.py fits NAMELIST [machine.json] [--rrtmg-batch N]
                                                  exit 0 if the case fits one GPU's G-MEM gate here, 1 if not
  machine.py capabilities [--samples DIR] [--out capabilities.md]
                                                  the capabilities table of the recorded profiles

Exit status of detect: 0 ok, 2 no GPU, 3 a GPU below compute capability 8.0 (the build targets cc80 and cc90 only).
"""

import argparse
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(REPO, "port"))
from nml import read_value, set_values  # noqa: E402

QUERY = ("index,name,uuid,memory.total,compute_cap,driver_version,pci.bus_id,"
         "ecc.mode.current,mig.mode.current,clocks.max.sm")
FULL_NAMELIST = os.path.join(REPO, "cases", "eaton_20250108", "namelist.input")
ESTIMATOR = os.path.join(REPO, "port", "gpu_mem_estimate.py")
GMEM_FRACTION = 0.85          # G-MEM: peak <= 85 % of one GPU (ADR-006 rev 2, point 4)
DEV_GMEM_GB = 25              # the dev case stays within 25 GB on every profile
MID_GPU_GB = 40               # eaton_mid must fit the smallest profile, one 40 GB GPU
RRTMG_BATCHES = (4096, 2048)  # preferred first
DEV_D02 = 181
# Streaming multiprocessors by GPU model (resident threads = SMs x 2048), until
# the device query of S0-04.5 measures them.  Unknown models: by compute capability.
SMS_BY_NAME = [(r"H100.*PCIe", 114), (r"H100", 132), (r"H200", 132), (r"A100", 108), (r"A30", 56), (r"A800", 108)]
SMS_BY_CC = {"8.0": 108, "9.0": 132}


# ---------------------------------------------------------------- parsing

def _read(d, name, default=""):
    p = os.path.join(d, name)
    return open(p, errors="replace").read() if os.path.exists(p) else default


def parse_gpus(text):
    lines = [l for l in text.splitlines() if l.strip()]
    if not lines or not lines[0].lower().startswith("index"):
        return []
    gpus = []
    for l in lines[1:]:
        c = [x.strip() for x in l.split(",")]
        if len(c) < 10:
            continue
        mem = int(re.sub(r"[^0-9]", "", c[3]) or 0)
        clk = re.sub(r"[^0-9]", "", c[9])
        gpus.append({
            "index": int(c[0]), "name": c[1], "uuid": c[2], "memory_mib": mem, "cc": c[4],
            "driver": c[5], "pci": c[6], "ecc": c[7], "mig": c[8],
            "max_sm_mhz": int(clk) if clk else None,
        })
    return gpus


def parse_cuda(text):
    m = re.search(r"CUDA Version:\s*([0-9.]+)", text)
    return m.group(1) if m else None


def parse_topo(text, n):
    """Link type between each pair of GPUs: {"0-1": "NV18" | "SYS" | ...}."""
    rows = {}
    for l in text.splitlines():
        m = re.match(r"^GPU(\d+)\s+(.*)$", l)
        if m:
            rows[int(m.group(1))] = m.group(2).split()
    links = {}
    for i in range(n):
        for j in range(i + 1, n):
            r = rows.get(i)
            links[f"{i}-{j}"] = r[j] if r and len(r) > j else "unknown"
    return links


def parse_lscpu(text):
    kv = {}
    for l in text.splitlines():
        if ":" in l:
            k, v = l.split(":", 1)
            kv[k.strip()] = v.strip()
    sockets = int(kv.get("Socket(s)", "1") or 1)
    cps = int(kv.get("Core(s) per socket", "0") or 0)
    tpc = int(kv.get("Thread(s) per core", "1") or 1)
    return {
        "cpu_model": kv.get("Model name", "unknown"),
        "vendor": kv.get("Vendor ID", "unknown"),
        "sockets": sockets,
        "cores_per_socket": cps,
        "threads_per_core": tpc,
        "cores": sockets * cps,
        "logical_cpus": int(kv.get("CPU(s)", "0") or 0),
    }


def parse_kv(text):
    out = {}
    for l in text.splitlines():
        if "=" in l:
            k, v = l.split("=", 1)
            out[k.strip()] = v.strip()
    return out


def gpu_model_key(name):
    """'NVIDIA A100-PCIE-40GB' -> 'a100-pcie-40gb' (keys GPU traces and tuning files)."""
    s = re.sub(r"^(NVIDIA|Tesla)\s+", "", name.strip(), flags=re.I)
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def short_hash(*parts):
    return hashlib.sha256("|".join(parts).encode()).hexdigest()[:12]


# ---------------------------------------------------------------- capabilities

def nominal_gb(mib):
    """Marketing size of a GPU: 40960 MiB -> 40, 81559 MiB -> 80."""
    return int(round(mib / 1024 / 8.0) * 8) if mib >= 8192 else int(round(mib / 1024))


def sms_of(name, cc):
    for pat, n in SMS_BY_NAME:
        if re.search(pat, name, re.I):
            return n
    return SMS_BY_CC.get(cc, 108)


def estimate_gb(namelist_text, gpu_gb, threads, batch):
    with tempfile.NamedTemporaryFile("w", suffix=".input", delete=False) as f:
        f.write(namelist_text)
        path = f.name
    try:
        out = subprocess.run([sys.executable, ESTIMATOR, path, "--gpu-gb", str(gpu_gb), "--threads", str(threads),
                              "--rrtmg-batch", str(batch)], capture_output=True, text=True, check=True).stdout
    finally:
        os.unlink(path)
    m = re.search(r"^TOTAL\s+([0-9.]+) GB", out, re.M)
    if not m:
        raise RuntimeError("gpu_mem_estimate.py printed no TOTAL line")
    return float(m.group(1))


def with_d02(text, n):
    we = read_value(text, "e_we").split(",")
    sn = read_value(text, "e_sn").split(",")
    we[1], sn[1] = f" {n}", f" {n}"
    return set_values(text, [("e_we", ",".join(we).strip() + ","), ("e_sn", ",".join(sn).strip() + ",")])


def case_namelists():
    """(name, namelist text, how it was obtained) of the cases the capabilities are computed for."""
    full = open(FULL_NAMELIST).read()
    cases = []
    for name, d02, how in (("eaton_small", DEV_D02, "full case with d02 181x181 (S0-09.1 makes the case)"),):
        p = os.path.join(REPO, "cases", name, "namelist.input")
        cases.append((name, open(p).read(), p) if os.path.exists(p) else (name, with_d02(full, d02), how))
    p = os.path.join(REPO, "cases", "eaton_mid", "namelist.input")
    cases.append(("eaton_mid", open(p).read(), p) if os.path.exists(p) else ("eaton_mid", None, "sized below"))
    cases.append(("eaton_full", full, os.path.relpath(FULL_NAMELIST, REPO)))
    return cases


def size_mid(threads):
    """Largest d02 (n = 9k + 1, the nest ratio) of the full case that fits one 40 GB GPU's gate."""
    full = open(FULL_NAMELIST).read()
    limit = GMEM_FRACTION * MID_GPU_GB
    best = None
    for batch in RRTMG_BATCHES:
        lo, hi = 1, (811 - 1) // 9
        while lo < hi:
            k = (lo + hi + 1) // 2
            if estimate_gb(with_d02(full, 9 * k + 1), MID_GPU_GB, threads, batch) <= limit:
                lo = k
            else:
                hi = k - 1
        n = 9 * lo + 1
        if best is None or n > best[0]:
            best = (n, batch)
    return best


def capabilities(gpus, host):
    if not gpus:
        return {"ok": False, "stop": "no GPU detected"}
    ccs = sorted({g["cc"] for g in gpus})
    if any(float(c) < 8.0 for c in ccs):
        return {"ok": False, "stop": f"compute capability {min(ccs)} < 8.0: the build targets cc80 and cc90 only"}
    mem_gb = min(nominal_gb(g["memory_mib"]) for g in gpus)
    limit = round(GMEM_FRACTION * mem_gb, 1)
    if limit == int(limit):
        limit = int(limit)
    n = len(gpus)
    threads = min(sms_of(g["name"], g["cc"]) for g in gpus) * 2048
    cases = {}
    mid_nl = None
    for name, text, how in case_namelists():
        if text is None:
            nmid, _ = size_mid(SMS_BY_CC["8.0"] * 2048)  # sized for the smallest profile, the same on all
            text = with_d02(open(FULL_NAMELIST).read(), nmid)
            how = f"estimated: largest d02 of a 40 GB gate = {nmid}x{nmid} (S0-09.5 decides)"
            mid_nl = nmid
        res = None
        for batch in RRTMG_BATCHES:
            gb = estimate_gb(text, mem_gb, threads, batch)
            res = {"estimate_gb": gb, "rrtmg_batch": batch, "fits": gb <= limit, "namelist": how}
            if res["fits"]:
                break
        if name == "eaton_small":
            res["within_dev_gate"] = res["estimate_gb"] <= DEV_GMEM_GB
        cases[name] = res
    cores = host["cores"] or host["logical_cpus"]
    ranks = sorted({1, max(1, cores // 4), max(1, cores // 2), cores})
    return {
        "ok": True,
        "gpu_memory_gb": mem_gb,
        "gmem_limit_gb": limit,
        "resident_threads": threads,
        "cases_on_one_gpu": [c for c, r in cases.items() if r["fits"]],
        "cases": cases,
        "eaton_mid_d02": mid_nl,
        "parallel_gpu_runs": n,
        "gpu_pair_check": "two GPUs" if n >= 2 else "same GPU twice",
        "acceptance_g5": ["eaton_mid"] + (["eaton_full"] if cases["eaton_full"]["fits"] else []),
        "full_case": "one GPU" + (" (multi-GPU if N >= 2)" if n >= 2 else "") if cases["eaton_full"]["fits"]
        else ("multi-GPU (S8-01 ... S8-05)" if n >= 2 else "not possible here"),
        "multi_gpu": n >= 2,
        "h100_only": all(float(c) >= 9.0 for c in ccs),
        "cpu_ranks": ranks,
        "build_jobs": max(1, min(cores, int(host.get("ram_gb", 0) // 4) or cores)),
        "rrtmg_batch": cases["eaton_small"]["rrtmg_batch"],
    }


def profile_name(gpus):
    """Name of the profile, from the numbers: <family>-<GB>x<count>, e.g. a100-40x2, h100-80x1."""
    if not gpus:
        return "no-gpu"
    fam = re.search(r"([AHBLV]\d{2,3})", gpus[0]["name"])
    fam = fam.group(1).lower() if fam else gpu_model_key(gpus[0]["name"]).split("-")[0]
    names = {g["name"] for g in gpus}
    mixed = "-mixed" if len(names) > 1 else ""
    return f"{fam}-{nominal_gb(min(g['memory_mib'] for g in gpus))}x{len(gpus)}{mixed}"


def known_profile(name):
    """The ADR-006 profile a detected profile belongs to (h100-80xN for any count)."""
    if re.fullmatch(r"h100-80x\d+", name):
        return "h100-80xN"
    return name if name in ("a100-40x2", "a100-80x1") else None


def detect(raw):
    gpus = parse_gpus(_read(raw, "gpus.csv"))
    host = parse_lscpu(_read(raw, "lscpu.txt"))
    m = re.search(r"MemTotal:\s*(\d+)\s*kB", _read(raw, "meminfo.txt"))
    host["ram_gb"] = round(int(m.group(1)) / 1024 / 1024, 1) if m else 0
    extra = parse_kv(_read(raw, "host.txt"))
    host["rapl_readable"] = extra.get("rapl", "unknown")
    host["key"] = short_hash(host["cpu_model"], str(host["sockets"]), str(host["cores_per_socket"]))
    prof = profile_name(gpus)
    gpu_models = sorted({gpu_model_key(g["name"]) for g in gpus})
    drivers = sorted({g["driver"] for g in gpus})
    rec = {
        "schema": 1,
        "profile": prof,
        "adr006_profile": known_profile(prof),
        "machine_id": short_hash(extra.get("id_source", "sample:" + os.path.basename(os.path.normpath(raw))),
                                 *sorted(g["uuid"] for g in gpus)),
        "gpu_key": "+".join(gpu_models) if gpu_models else "none",
        "gpus": gpus,
        "gpu_links": parse_topo(_read(raw, "topo.txt"), len(gpus)),
        "driver": drivers[0] if len(drivers) == 1 else drivers,
        "cuda": parse_cuda(_read(raw, "nvidia-smi.txt")),
        "host": host,
        "container": {"runtime": extra.get("container", "unknown"), "usable": extra.get("container_usable", "unknown"),
                      "detected_in": extra.get("detected_in", "sample")},
    }
    rec["capabilities"] = capabilities(gpus, host)
    return rec


# ---------------------------------------------------------------- output

def summary(rec):
    c = rec["capabilities"]
    h = rec["host"]
    out = [f"machine   {rec['machine_id']}  profile {rec['profile']}"
           + (f" (ADR-006 {rec['adr006_profile']})" if rec["adr006_profile"] else " (not a listed profile: rules apply)")]
    for g in rec["gpus"]:
        out.append(f"gpu {g['index']}     {g['name']}  {g['memory_mib']} MiB  cc {g['cc']}  ECC {g['ecc']}  MIG {g['mig']}")
    if rec["gpu_links"]:
        out.append("links     " + "  ".join(f"{k}:{v}" for k, v in rec["gpu_links"].items()))
    out.append(f"driver    {rec['driver']}  CUDA {rec['cuda']}")
    out.append(f"host      {h['cpu_model']}  {h['sockets']} x {h['cores_per_socket']} cores  {h['ram_gb']} GB RAM  "
               f"host key {h['key']}  RAPL {h['rapl_readable']}")
    out.append(f"container {rec['container']['runtime']} (usable: {rec['container']['usable']}; "
               f"detected in {rec['container']['detected_in']})")
    if not c["ok"]:
        out.append(f"STOP      {c['stop']}")
        return "\n".join(out)
    out.append(f"G-MEM     {c['gmem_limit_gb']} GB per GPU ({int(GMEM_FRACTION * 100)} % of {c['gpu_memory_gb']} GB)")
    for name, r in c["cases"].items():
        out.append(f"case      {name:<11} {r['estimate_gb']:6.2f} GB  RRTMG {r['rrtmg_batch']}  "
                   f"{'fits one GPU' if r['fits'] else 'does NOT fit one GPU'}")
    out.append(f"runs      {c['parallel_gpu_runs']} at once; GPU pair checks: {c['gpu_pair_check']}; "
               f"multi-GPU {'yes' if c['multi_gpu'] else 'no'}; H100-only steps {'yes' if c['h100_only'] else 'no'}")
    out.append(f"G5        {', '.join(c['acceptance_g5'])}; full case: {c['full_case']}")
    out.append(f"CPU-REF   ranks {', '.join(map(str, c['cpu_ranks']))}; BUILD_JOBS {c['build_jobs']}")
    return "\n".join(out)


def get(rec, key):
    v = rec
    for k in key.split("."):
        if isinstance(v, list):
            v = v[int(k)]
        else:
            v = v[k]
    if isinstance(v, bool):
        return "yes" if v else "no"
    if isinstance(v, list):
        return " ".join(map(str, v))
    return str(v)


def diff(old, new):
    gpu = old["gpu_key"] != new["gpu_key"] or old["driver"] != new["driver"]
    host = old["host"]["key"] != new["host"]["key"]
    if old["machine_id"] == new["machine_id"] and not gpu and not host:
        return "same"
    return "+".join(x for x, y in (("gpu", gpu), ("host", host)) if y) or "machine"


def capabilities_md(samples):
    recs = []
    for d in sorted(os.listdir(samples)):
        p = os.path.join(samples, d)
        if os.path.isdir(p):
            recs.append((d, detect(p), _read(p, "SOURCE").strip()))
    good = [(d, r, s) for d, r, s in recs if r["capabilities"]["ok"]]
    yn = lambda b: "yes" if b else "no"  # noqa: E731
    head = "| Item | Rule | " + " | ".join(f"`{r['profile']}`" for _, r, _ in good) + " |"
    rows = [head, "|---|---|" + "---|" * len(good)]

    def row(item, rule, f):
        rows.append(f"| {item} | {rule} | " + " | ".join(f(r["capabilities"], r) for _, r, _ in good) + " |")

    row("GPUs", "detected", lambda c, r: f"{len(r['gpus'])} × {r['gpus'][0]['name']}")
    row("Compute capability", "≥ 8.0, else stop", lambda c, r: r["gpus"][0]["cc"])
    row("Memory gate G-MEM", "peak ≤ 85 % of one GPU's memory", lambda c, r: f"{c['gmem_limit_gb']} GB")
    for case in ("eaton_small", "eaton_mid", "eaton_full"):
        row(f"`{case}` on one GPU", "memory estimate (RRTMG 4096, else 2048) ≤ G-MEM",
            lambda c, r, k=case: f"{yn(c['cases'][k]['fits'])} ({c['cases'][k]['estimate_gb']:.1f} GB, "
                                 f"{c['cases'][k]['rrtmg_batch']})")
    row("Runs at once", "one per GPU", lambda c, r: str(c["parallel_gpu_runs"]))
    row("\"GPU 0 equals GPU 1\" checks", "on two GPUs, else the same GPU twice", lambda c, r: c["gpu_pair_check"])
    row("Acceptance G5", "`eaton_mid` always; the full case where it fits one GPU",
        lambda c, r: " + ".join(f"`{x}`" for x in c["acceptance_g5"]))
    row("Full case", "one GPU if it fits, else multi-GPU", lambda c, r: c["full_case"])
    row("Multi-GPU phases S8-01 … S8-05", "≥ 2 GPUs", lambda c, r: yn(c["multi_gpu"]))
    row("H100-only optimizations", "cc ≥ 9.0", lambda c, r: yn(c["h100_only"]))
    row("CPU reference ranks", "1, n/4, n/2, n host cores", lambda c, r: ", ".join(map(str, c["cpu_ranks"])))
    row("BUILD_JOBS", "host cores, at most RAM/4 GB", lambda c, r: str(c["build_jobs"]))
    mids = {r["capabilities"]["eaton_mid_d02"] for _, r, _ in good} - {None}
    out = [
        "# Machine capabilities",
        "",
        "<!-- GENERATED by `python3 port/h100/machine.py capabilities --out port/machines/capabilities.md`: do not edit -->",
        "",
        "What each GPU machine profile can run (ADR-006 rev 2, phase S0-00). Every value is derived by",
        "`port/h100/machine.py` from the detected numbers (GPU memory, count, compute capability, host cores),",
        "never from the profile name, so a machine that is not listed gets its column from the same rules:",
        "`bash port/h100/machine.sh detect` prints it.",
        "",
        "\n".join(rows),
        "",
        "Notes:",
        f"- Memory estimates: `port/gpu_mem_estimate.py` with resident threads = SMs × 2048 of the GPU model. "
        f"`eaton_small` is the full case with d02 {DEV_D02}×{DEV_D02} until S0-09.1 writes `cases/eaton_small/`; "
        f"it must also stay within {DEV_GMEM_GB} GB on every profile.",
        f"- `eaton_mid` is sized by the same tool: the largest d02 (n = 9k + 1) of the full case whose estimate fits "
        f"the gate of one 40 GB GPU. Estimated d02: {', '.join(f'{m}×{m}' for m in sorted(mids)) or 'from its namelist'}."
        " S0-09.5 decides and writes `cases/eaton_mid/`.",
        "- A GPU below compute capability 8.0 stops every script (sample `v100-16x1`).",
        "",
        "Samples the table is computed from (`port/machines/samples/`):",
        "",
    ]
    for d, r, s in recs:
        out.append(f"- `{d}`: {s or 'no SOURCE'}" + ("" if r["capabilities"]["ok"] else
                                                   f" → stops: {r['capabilities']['stop']}"))
    return "\n".join(out) + "\n"


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("detect"); p.add_argument("raw"); p.add_argument("--out"); p.add_argument("--quiet", action="store_true")
    p = sub.add_parser("show"); p.add_argument("json", nargs="?", default=os.path.join(os.environ.get("WORK", "."), "machine.json"))
    p = sub.add_parser("get"); p.add_argument("key"); p.add_argument("json", nargs="?", default=os.path.join(os.environ.get("WORK", "."), "machine.json"))
    p = sub.add_parser("diff"); p.add_argument("old"); p.add_argument("new")
    p = sub.add_parser("fits"); p.add_argument("namelist"); p.add_argument("json", nargs="?", default=os.path.join(os.environ.get("WORK", "."), "machine.json")); p.add_argument("--rrtmg-batch", type=int, default=int(os.environ.get("WRF_RRTMG_BATCH", "4096")))
    p = sub.add_parser("capabilities"); p.add_argument("--samples", default=os.path.join(REPO, "port", "machines", "samples")); p.add_argument("--out")
    a = ap.parse_args(argv)
    if a.cmd == "detect":
        rec = detect(a.raw)
        if a.out:
            with open(a.out, "w") as f:
                json.dump(rec, f, indent=1, sort_keys=True)
                f.write("\n")
        if not a.quiet:
            print(summary(rec))
        if not rec["gpus"]:
            return 2
        return 0 if rec["capabilities"]["ok"] else 3
    if a.cmd in ("show", "get"):
        if not os.path.exists(a.json):
            print(f"no machine record {a.json}: run bash port/h100/machine.sh detect", file=sys.stderr)
            return 1
        rec = json.load(open(a.json))
        print(summary(rec) if a.cmd == "show" else get(rec, a.key))
        return 0
    if a.cmd == "diff":
        print(diff(json.load(open(a.old)), json.load(open(a.new))))
        return 0
    if a.cmd == "fits":
        rec = json.load(open(a.json))
        c = rec["capabilities"]
        gb = estimate_gb(open(a.namelist).read(), c["gpu_memory_gb"], c["resident_threads"], a.rrtmg_batch)
        ok = gb <= c["gmem_limit_gb"]
        print(f"{a.namelist}: estimate {gb:.2f} GB (RRTMG {a.rrtmg_batch}) vs G-MEM {c['gmem_limit_gb']} GB "
              f"of {rec['profile']}: {'fits' if ok else 'does NOT fit one GPU'}")
        return 0 if ok else 1
    if a.cmd == "capabilities":
        md = capabilities_md(a.samples)
        if a.out:
            open(a.out, "w").write(md)
        else:
            sys.stdout.write(md)
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
