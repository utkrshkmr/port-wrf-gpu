#!/bin/bash
# Detect the GPU machine at hand (phase S0-00; ADR-006 rev 2).  Run first in
# every session, before any build or gate.
#
#   machine.sh detect   collect nvidia-smi / lscpu outputs (nvidia-smi inside the
#                       container when the container works, else on the host) into
#                       $WORK/machine/raw, derive the profile and capabilities
#                       (machine.py), write $WORK/machine.json and print the profile;
#                       says when the machine-change protocol (port/gates/t_machine.sh)
#                       has to run
#   machine.sh show     print the recorded profile
#   machine.sh get KEY  one value of $WORK/machine.json (dotted key, e.g. capabilities.gmem_limit_gb)
#   machine.sh check    exit 0 if this machine is detected and its change protocol passed
#                       (the record $WORK/machine/protocol.json has the same machine id), else 1
#                       with the instruction
#
# Exit status of detect: 0 ok, 2 no GPU, 3 a GPU below compute capability 8.0.
set -uo pipefail
source "$(dirname "$0")/common.sh"
MDIR=$WORK/machine
MJSON=$WORK/machine.json
PROTO=$MDIR/protocol.json
mpy() { python3 "$HERE_H100/machine.py" "$@"; }

container_usable() {
  case ${CONTAINER:-none} in
    none) [ -n "${NVHPC_ROOT:-}" ] && [ -x "$NVHPC_ROOT/compilers/bin/nvfortran" ] ;;
    apptainer|singularity) command -v "$CONTAINER" >/dev/null && [ -f "$IMAGE" ] ;;
    podman) command -v podman >/dev/null && podman image exists "$IMAGE" 2>/dev/null ;;
    docker) command -v docker >/dev/null && docker image inspect "$IMAGE" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

detect() {
  local raw=$MDIR/raw where=host smi=(nvidia-smi)
  mkdir -p "$raw"
  if container_usable && x nvidia-smi -L >/dev/null 2>&1; then where=container; smi=(x nvidia-smi); fi
  command -v nvidia-smi >/dev/null || [ $where = container ] || { echo "ERROR: nvidia-smi not found: no GPU here" >&2; return 2; }
  "${smi[@]}" --query-gpu=index,name,uuid,memory.total,compute_cap,driver_version,pci.bus_id,ecc.mode.current,mig.mode.current,clocks.max.sm \
    --format=csv > "$raw/gpus.csv" 2>/dev/null || : > "$raw/gpus.csv"
  "${smi[@]}" 2>/dev/null | sed -n 1,6p > "$raw/nvidia-smi.txt"
  "${smi[@]}" topo -m 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' > "$raw/topo.txt"
  LC_ALL=C lscpu > "$raw/lscpu.txt"
  grep MemTotal /proc/meminfo > "$raw/meminfo.txt"
  local rapl=no
  for f in /sys/class/powercap/intel-rapl:*/energy_uj; do [ -r "$f" ] && cat "$f" >/dev/null 2>&1 && rapl=yes && break; done
  local idsrc
  idsrc=$( (cat /etc/machine-id 2>/dev/null || cat /var/lib/dbus/machine-id 2>/dev/null || echo unknown) | sha256sum | cut -c1-16)
  {
    echo "id_source=$idsrc"
    echo "rapl=$rapl"
    echo "container=${CONTAINER:-none}"
    echo "container_usable=$(container_usable && echo yes || echo no)"
    echo "detected_in=$where"
    container_usable && echo "compiler=$(x nvfortran --version 2>/dev/null | awk 'NF {print $2; exit}')"
  } > "$raw/host.txt"
  [ -f "$MJSON" ] && cp "$MJSON" "$MDIR/machine.prev.json"
  mpy detect "$raw" --out "$MJSON"; local rc=$?
  [ $rc = 0 ] || return $rc
  echo "record    $MJSON"
  if [ ! -f "$PROTO" ]; then
    echo "protocol  never run on this work area: bash port/gates/t_machine.sh"
  else
    local d; d=$(mpy diff "$PROTO" "$MJSON")
    if [ "$d" != same ]; then echo "protocol  REQUIRED (changed: $d): bash port/gates/t_machine.sh"
    elif [ "$(mpy get protocol_result "$PROTO")" = PASS ]; then echo "protocol  passed for this machine ($(mpy get protocol_date "$PROTO"))"
    else echo "protocol  FAILED for this machine ($(mpy get protocol_date "$PROTO")): see $PROTO; rerun bash port/gates/t_machine.sh after the fix"; fi
  fi
  return 0
}

check() {
  [ -f "$MJSON" ] || { echo "machine not detected: run bash port/h100/machine.sh detect" >&2; return 1; }
  [ -f "$PROTO" ] || { echo "machine-change protocol not run here: bash port/gates/t_machine.sh" >&2; return 1; }
  local d; d=$(mpy diff "$PROTO" "$MJSON")
  [ "$d" = same ] || { echo "machine changed ($d) since the last protocol: bash port/gates/t_machine.sh" >&2; return 1; }
  [ "$(mpy get protocol_result "$PROTO")" = PASS ] || { echo "the machine-change protocol did not pass: see $PROTO" >&2; return 1; }
  local pend; pend=$(mpy get pending "$PROTO")
  if [ -n "$pend" ] && container_usable; then
    echo "the toolchain is here now; the protocol has pending items ($pend): bash port/gates/t_machine.sh" >&2; return 1
  fi
  [ -z "$pend" ] || echo "machine protocol passed; pending until the toolchain exists: $pend" >&2
}

case ${1:-} in
  detect) detect ;;
  show) mpy show "$MJSON" ;;
  get) [ $# -ge 2 ] || die "usage: machine.sh get KEY"; mpy get "$2" "$MJSON" ;;
  check) check ;;
  *) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
