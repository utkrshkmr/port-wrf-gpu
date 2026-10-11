#!/bin/bash
# Gate S0-04: a hello-world OpenACC kernel and a CUDA Fortran kernel on every
# GPU of the machine (ACC_DEVICE_TYPE=nvidia), with the GPU-port device flags;
# the CUDA Fortran program also prints the device query of S0-04.5.
#
#   gpu_hello.sh            builds in $WORK/gpu_hello, prints one PASS/FAIL line per GPU and program
set -uo pipefail
source "$(dirname "$0")/common.sh"
src=$HERE_H100/gpu_hello
d=$WORK/gpu_hello; mkdir -p "$d"; cd "$d" || exit 1
fail=0
x nvfortran -w -Mfree -O2 -Kieee -Mnofma -Mnoflushz -Mnodaz -tp=haswell -acc=gpu -cuda -gpu=cc80,cc90,nofma,noflushz \
  -o acc_hello "$src/acc_hello.F90" > build_acc.log 2>&1 || { echo "FAIL   build acc_hello (build_acc.log)"; fail=1; }
x nvfortran -cuda -gpu=cc80,cc90,nofma,noflushz -o cuf_devq "$src/cuf_devq.cuf" > build_cuf.log 2>&1 \
  || { echo "FAIL   build cuf_devq (build_cuf.log)"; fail=1; }
n=$(nvidia-smi -L | grep -c '^GPU')
for g in $(seq 0 $((n - 1))); do
  out=$(CUDA_VISIBLE_DEVICES=$g ACC_DEVICE_TYPE=nvidia NVCOMPILER_ACC_NOTIFY=1 x ./acc_hello 2>&1)
  if echo "$out" | grep -q 'launch CUDA kernel' && echo "$out" | grep -q 'c(n)=    4.3750'; then echo "PASS   GPU $g OpenACC kernel"
  else echo "FAIL   GPU $g OpenACC kernel"; echo "$out" | tail -3; fail=1; fi
  CUDA_VISIBLE_DEVICES=$g x ./cuf_devq > devq_$g.txt 2>&1
  if grep -q 'CUDA Fortran kernel PASS' devq_$g.txt; then echo "PASS   GPU $g CUDA Fortran kernel ($(sed -n 's/^name *//p' devq_$g.txt), device query in $d/devq_$g.txt)"
  else echo "FAIL   GPU $g CUDA Fortran kernel"; tail -3 devq_$g.txt; fail=1; fi
done
echo "== gpu_hello: $([ $fail = 0 ] && echo PASS || echo FAIL)  (machine $(machine_line))"
exit $fail
