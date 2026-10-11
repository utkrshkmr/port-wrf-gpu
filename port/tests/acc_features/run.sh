#!/bin/bash
# Build and run every OpenACC probe separately (a compile failure is itself a
# result) and print one table row per probe; writes probes_<gpu>_<date>.md.
#   run.sh            nvfortran on the GPU (CUDA_VISIBLE_DEVICES picks it); TC as in run_ref_tests.sh
#   run.sh gnu        gfortran, host only (compile check; device-only probes are skipped)
# Exit status 0 only if every probe built and printed PASS.
set -u
comp=${1:-nvhpc}
cd "$(dirname "$0")"
gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader -i "${CUDA_VISIBLE_DEVICES:-0}" 2>/dev/null | tr ' ' '_' | head -1)
out="probes_${gpu:-host}_$(date +%Y%m%d_%H%M%S).md"
{
  echo "# OpenACC feature probes (S0-05): ${gpu:-host} $(date -u +%FT%TZ)"
  echo; echo '```'; ${TC:-} bash -c "$([ "$comp" = gnu ] && echo gfortran || echo nvfortran) --version" 2>/dev/null | grep -v '^$' | head -1; echo '```'; echo
  echo "| Probe | Build | Result |"; echo "|---|---|---|"
} > "$out"
probes=$(make -s -pn COMPILER=$comp 2>/dev/null | sed -n 's/^PROBES = //p' | head -1)
fail=0
make -s clean >/dev/null 2>&1   # never reuse binaries of the other compiler
for p in $probes; do
  if ${TC:-} make -s COMPILER=$comp $p > build_$p.log 2>&1; then
    b=ok
    res=$(NV_ACC_CUDA_STACKSIZE=65536 ACC_DEVICE_TYPE=$([ "$comp" = gnu ] && echo host || echo nvidia) \
          timeout 300 ${TC:-} ./$p 2>&1); rc=$?
    res=$(echo "$res" | grep PROBE | sed 's/^PROBE //' | tr '\n' ';' | sed 's/;$//')
    [ -z "$res" ] && res="no PROBE line (exit $rc)"
  else
    b="FAILED (build_$p.log: $(grep -m1 -iE 'error|severe' build_$p.log | cut -c1-80))"; res="-"
  fi
  echo "$res" | grep -q FAIL && fail=1
  [ "$b" = ok ] && echo "$res" | grep -q PASS || fail=1
  echo "| $p | $b | $res |" | tee -a "$out"
done
echo "acc_features ($comp): $([ $fail = 0 ] && echo PASS || echo FAIL)  ($out)" | tee -a "$out"
exit $fail
