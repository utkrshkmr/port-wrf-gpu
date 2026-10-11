#!/bin/bash
# T-MACHINE: the machine-change protocol (phase S0-00.4; ADR-006 rev 2, point 6).
# Runs when port/h100/machine.sh detect says the machine is new or changed, and
# before any other gate on that machine.
#
#   t_machine.sh [--force]
#
# Steps:
#   a  toolchain: nvfortran, image and driver/CUDA recorded
#   b  new GPU model or driver: the device arithmetic tests and OpenACC probes
#      (S0-06 run_ref_tests.sh nvhpc, S0-05 port/tests/acc_features) on this GPU
#   c  new host (T-XM): CPU-REF here vs the archived references of another host
#      ($WORK/reference/<case>/<host-key>/) on T0, T1 and W-20
#   d  T-XG: GPU-REPRO of the current commit vs archived GPU traces of other GPU
#      models ($WORK/reference/gpu/<commit>/<gpu-model>/)
#   e  record: port/machines/<id>.json (repository) and $WORK/machine/protocol.json
#
# A step that has nothing to compare against (the first machine, no archive yet)
# records that and passes.  A step whose tools do not exist yet (before S0-04,
# S0-05, S0-06, S0-13) is recorded as "pending <phase>": the protocol passes, and
# the pending items are listed in the record, so the next run of t_machine.sh
# after those phases runs them (machine.sh check asks for it when the record has
# pending items and the toolchain has appeared).
set -uo pipefail
GATE_NO_MACHINE=1 source "$(dirname "$0")/lib.sh"
M=$H100/machine.sh
MJSON=$WORK/machine.json
MDIR=$WORK/machine
PROTO=$MDIR/protocol.json
mpy() { python3 "$H100/machine.py" "$@"; }

bash "$M" detect > "$GATE_DIR/machine.txt" 2>&1; rc=$?
cat "$GATE_DIR/machine.txt"
[ $rc = 0 ] || { result T-MACHINE FAIL "machine.sh detect stopped (exit $rc)"; gate_end t_machine; }
id=$(mpy get machine_id "$MJSON"); gpu=$(mpy get gpu_key "$MJSON"); hostkey=$(mpy get host.key "$MJSON")
change=new
[ -f "$PROTO" ] && change=$(mpy diff "$PROTO" "$MJSON")
have_fc() { x nvfortran --version >/dev/null 2>&1; }
if [ "$change" = same ] && [ "${1:-}" != --force ] && [ "$(mpy get protocol_result "$PROTO")" = PASS ] \
   && { [ -z "$(mpy get pending "$PROTO")" ] || ! have_fc; }; then
  result T-MACHINE PASS "machine $id unchanged since $(mpy get protocol_date "$PROTO"); nothing to do"; [ -n "$(mpy get pending "$PROTO")" ] && note "pending until the toolchain exists: $(mpy get pending "$PROTO")"
  gate_end t_machine
fi
note "machine $id ($(mpy get profile "$MJSON")): change since the last protocol: $change"
pending=()
steps=$MDIR/steps.txt; : > "$steps"
step() { echo "$1|$2|$3" >> "$steps"; result "$1" "$2" "$3"; }

# a: toolchain
fc=$(x nvfortran --version 2>/dev/null | awk 'NF {print; exit}')
if [ -n "$fc" ]; then step T-MACHINE-a PASS "$fc; driver $(mpy get driver "$MJSON"); CUDA $(mpy get cuda "$MJSON")"
else step T-MACHINE-a PASS "no nvfortran yet (S0-04); driver $(mpy get driver "$MJSON"), CUDA $(mpy get cuda "$MJSON") recorded"
  pending+=(S0-04); fi

# b: device arithmetic and probes, once per GPU model + driver + compiler
devkey="$gpu-$(mpy get driver "$MJSON")"
devok=$MDIR/devtests/$devkey.ok
if [ -f "$devok" ]; then step T-MACHINE-b PASS "device tests already passed for $devkey ($(head -1 "$devok"))"
elif [ -z "$fc" ]; then step T-MACHINE-b PASS "pending S0-05/S0-06: no compiler to build the device tests yet"; pending+=(S0-05 S0-06)
else
  ok=1; detail=""
  # T-FMA, T-IEEE, T-IPOW, T-RM-* (quick sizes) on every GPU of the machine; T-FMA first
  rm_dir=$PORT_REPO/port/tests/repro_math
  if (cd "$rm_dir" && x make -s > "$GATE_DIR/machine_repro_math_build.log" 2>&1); then
    for g in $(seq 0 $(( $(mpy get capabilities.parallel_gpu_runs "$MJSON") - 1 ))); do
      gd=$GATE_DIR/repro_math_gpu$g; mkdir -p "$gd"
      cp "$rm_dir"/t_fma "$rm_dir"/t_ieee "$rm_dir"/t_ipow "$rm_dir"/t_rm_exh "$rm_dir"/t_rm_pow "$rm_dir"/t_rm_d \
         "$rm_dir"/fma_cases.bin "$rm_dir"/run_tests.sh "$gd"/
      if (cd "$gd" && CUDA_VISIBLE_DEVICES=$g ACC_DEVICE_TYPE=nvidia OMP_NUM_THREADS=$(( $(nproc) / 4 )) \
            x bash ./run_tests.sh quick > run.log 2>&1); then detail="$detail repro_math GPU $g PASS;"
      else ok=0; detail="$detail repro_math GPU $g FAIL ($gd/run.log);"; fi
    done
  else ok=0; detail="repro_math build FAIL;"; fi
  if [ -x "$PORT_REPO/port/tests/run_ref_tests.sh" ] || [ -f "$PORT_REPO/port/tests/run_ref_tests.sh" ]; then
    rr=PASS; TC="bash $H100/x.sh" bash "$PORT_REPO/port/tests/run_ref_tests.sh" nvhpc > "$GATE_DIR/machine_ref_tests.log" 2>&1 || { ok=0; rr=FAIL; }
    detail="$detail ref tests $rr"
  fi
  if [ -f "$PORT_REPO/port/tests/acc_features/run.sh" ]; then
    TC="bash $H100/x.sh" bash "$PORT_REPO/port/tests/acc_features/run.sh" > "$GATE_DIR/machine_acc_features.log" 2>&1 || ok=0
    detail="$detail; acc_features $(grep -c PASS "$GATE_DIR/machine_acc_features.log") PASS"
  else pending+=(S0-05); detail="$detail; acc_features pending S0-05"; fi
  if [ $ok = 1 ]; then mkdir -p "$MDIR/devtests"; echo "$(date -u +%F) $fc" > "$devok"; step T-MACHINE-b PASS "$devkey: $detail"
  else step T-MACHINE-b FAIL "$devkey: $detail (logs in $GATE_DIR)"; fi
fi

# c: T-XM, the archived CPU-REF references of other hosts
others=$(find "$WORK/reference" -mindepth 2 -maxdepth 2 -type d ! -name "$hostkey" ! -path '*/gpu/*' 2>/dev/null | head -20)
if [ -z "$others" ]; then step T-MACHINE-c PASS "T-XM: no archived reference of another host (host key $hostkey): nothing to compare"
elif [ -f "$PORT_REPO/port/gates/t_tiers.sh" ]; then
  if REF_HOST_KEYS="$others" bash "$PORT_REPO/port/gates/t_tiers.sh" cpu-ref T0 T1 > "$GATE_DIR/machine_txm.log" 2>&1; then
    step T-MACHINE-c PASS "T-XM bitwise: the archived references are valid on host $hostkey"
  else step T-MACHINE-c FAIL "T-XM not bitwise: regenerate the references on host $hostkey before any GPU comparison"; fi
else step T-MACHINE-c FAIL "archives of other hosts exist but t_tiers.sh (S0-13) does not: T-XM cannot run"; fi

# d: T-XG, archived GPU traces of the same commit on other GPU models
commit=$(git -C "$PORT_REPO" rev-parse --short=12 HEAD)
xg=$(find "$WORK/reference/gpu/$commit" -mindepth 1 -maxdepth 1 -type d ! -name "$gpu" 2>/dev/null | head -5)
if [ -z "$xg" ]; then step T-MACHINE-d PASS "T-XG: no GPU traces of commit $commit from another GPU model: nothing to compare"
else step T-MACHINE-d FAIL "T-XG: traces of other GPU models exist ($xg) but the T-XG comparison needs S0-13 (t_tiers.sh)"; fi

# e: record
res=PASS; grep -q '|FAIL|' "$steps" && res=FAIL
pend=$(printf '%s\n' "${pending[@]}" | sort -u | tr '\n' ' ' | sed 's/ $//')
python3 - "$MJSON" "$PROTO" "$PORT_REPO/port/machines/$id.json" "$steps" "$res" "$pend" "$change" "$commit" <<'EOF'
import json, sys, datetime, copy
mj, proto, repo_rec, steps, res, pend, change, commit = sys.argv[1:9]
rec = json.load(open(mj))
rec["protocol_date"] = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
rec["protocol_result"] = res
rec["protocol_change"] = change
rec["protocol_commit"] = commit
rec["pending"] = pend.split() if pend else []
rec["protocol_steps"] = [dict(zip(("step", "result", "detail"), l.rstrip("\n").split("|", 2))) for l in open(steps)]
json.dump(rec, open(proto, "w"), indent=1, sort_keys=True)
pub = copy.deepcopy(rec)                       # the repository copy: no hardware serials
for g in pub["gpus"]:
    g.pop("uuid", None); g.pop("pci", None)
hist = []
try:
    hist = json.load(open(repo_rec)).get("protocol_history", [])
except Exception:
    pass
hist.append({k: rec[k] for k in ("protocol_date", "protocol_result", "protocol_change", "protocol_commit", "pending")})
pub["protocol_history"] = hist
pub.pop("protocol_steps", None); pub["last_protocol_steps"] = rec["protocol_steps"]
json.dump(pub, open(repo_rec, "w"), indent=1, sort_keys=True)
open(repo_rec, "a").write("\n")
EOF
step T-MACHINE-e PASS "recorded port/machines/$id.json and $PROTO${pend:+; pending: $pend}"
[ $res = PASS ] && result T-MACHINE PASS "machine $id, profile $(mpy get profile "$MJSON")" || result T-MACHINE FAIL "machine $id"
gate_end t_machine
