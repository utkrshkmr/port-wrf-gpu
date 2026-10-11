# OpenACC feature probes (roadmap/plan-4.6 S0-05).  Use run.sh.
#   make                 nvfortran with the GPU-REPRO device flags (A100 cc80, H100 cc90)
#   make COMPILER=gnu    gfortran -fopenacc, host only: a compile check on CLOUD
COMPILER ?= nvhpc
TP       ?= haswell
ifeq ($(COMPILER),nvhpc)
FC     = nvfortran
FFLAGS = -O2 -Kieee -Mnofma -Mnoflushz -Mnodaz -Mvect=noassoc -tp=$(TP) \
         -acc=gpu -cuda -gpu=cc80,cc90,nofma,noflushz -Minfo=accel
PROBES = f_if f_routine f_declare f_present f_stmtfn f_intproc f_opt f_char f_red f_nan f_stack \
         f_attach f_hostdata f_cache_async f_auto f_bound
else
FC     = gfortran
FFLAGS = -O2 -ffp-contract=off -fopenacc -ffree-line-length-none
PROBES = f_if f_routine f_declare f_present f_stmtfn f_intproc f_opt f_char f_red f_nan \
         f_attach f_cache_async f_auto f_bound
endif
all: $(PROBES)
# F-BOUND uses rp_min of WRF's module_repro_math, preprocessed with REPRO_MATH
module_repro_math.f90: ../../../WRF/frame/module_repro_math.F
	cpp -P -traditional-cpp -DREPRO_MATH $< > $@
module_repro_math.o: module_repro_math.f90
	$(FC) $(FFLAGS) -c $<
f_bound: f_bound.F90 module_repro_math.o
	$(FC) $(FFLAGS) -o $@ $< module_repro_math.o
f_%: f_%.F90
	$(FC) $(FFLAGS) -o $@ $<
clean:
	rm -f *.o *.mod f_if f_routine f_declare f_present f_stmtfn f_intproc f_opt f_char f_red f_nan f_stack \
	      f_attach f_hostdata f_cache_async f_auto f_bound build_*.log module_repro_math.f90
.PHONY: all clean
