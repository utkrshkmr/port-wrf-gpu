#!/bin/bash
# Build WRF for the port (plan.md 4) on the H100 machine.
#
#   build.sh <mode> [--commit REV | --worktree] [--clean] [--fire-ideal] [--fine] [--uninit nan|zero] [--tag T]
#
# mode        cpu-ref | gpu-repro | gpu-debug   (the NVHPC "GPU port" stanzas, dmpar)
#             gnu                               (gfortran serial; only for testing these
#                                                scripts on a machine without NVHPC)
#             gnu-ref | gnu-gpu                 (gfortran serial, for checking code without NVHPC
#                                                or a GPU, port/agent/CODE_ONLY.md section 7):
#               gnu-ref  -DREPRO_MATH -DWRF_POOL -frecursive          the CPU view (as CPU-REF)
#               gnu-gpu  -DREPRO_MATH -DWRF_POOL -DWRF_GPU -fopenacc  the GPU view; OpenACC regions
#                        run on the host (gfortran host fallback), so a gnu-gpu run equals the gnu-ref run
#                        bit for bit when the GPU code keeps the arithmetic
# --commit REV  clean build of a commit (default HEAD) in $WORK/builds/<mode>/<sha12>[-T];
#               reused if it exists.  The reference builds come from commits.
# --worktree    incremental build of the working tree (committed or not) in
#               $WORK/builds/<mode>/worktree[-T]: only changed files are copied,
#               make recompiles what depends on them.  This is the edit-build-test loop.
# --clean       remove the build directory first (--worktree) / rebuild (--commit)
# --fire-ideal  also build ideal.exe of em_fire (main/ideal_fire.exe) for the smoke case
# --fine        fine-tracing build: adds -DWRF_TRACE_FINE (level-3 checkpoints, port/agent/DEBUGGING.md);
#               directory <...>-fine, mode <mode>-fine in BUILD_INFO.  Same arithmetic flags.
# --uninit V    gnu only (T-UNINIT, port/gates/t_uninit.sh): every local variable starts as
#               signaling NaN (V=nan) or zero (V=zero); directory <...>-uninit-V.
# gnu builds use the gfortran netCDF $NETCDF_GNU (setup_toolchain.sh deps-gnu) when it exists.
#
# The last line printed is the build directory.  BUILD_INFO in it records the
# mode, the source (commit, or HEAD + md5 of the uncommitted diff), the
# compiler and the md5 of wrf.exe.  compile.log keeps the compiler output
# (GPU builds: -Minfo=mp lines show which loops were offloaded).
set -euo pipefail
source "$(dirname "$0")/common.sh"

apply_o1_list() {
  local cfg=${1:?}
  local bmode=${2:-cpu-ref}
  local list_file=${O1_LIST:-$HERE_H100/o1_files.txt}
  local target_dir
  target_dir=$(dirname "$cfg")

  local old_objs=()
  if [ -f "$cfg" ]; then
    mapfile -t old_objs < <(sed -n -E 's/^([a-zA-Z0-9_.]+) *: *FCOPTIM *:=.*/\1/p' "$cfg" | sort -u)
    sed -i -E '/^[a-zA-Z0-9_.]+[[:space:]]*:[[:space:]]*FCOPTIM[[:space:]]*:=/d' "$cfg"
  fi

  local new_objs=()
  local md5="none"
  local count=0

  if [[ $bmode != gnu* ]] && [ "$list_file" != "none" ]; then
    [ -f "$list_file" ] || die "O1_LIST file not found: $list_file"
    md5=$(md5sum < "$list_file" | cut -d' ' -f1)
    mapfile -t new_objs < <(grep -v '^[[:space:]]*#' "$list_file" | grep -v '^[[:space:]]*$' | awk '{print $1}' | sort -u)
    count=${#new_objs[@]}

    for obj in "${new_objs[@]}"; do
      printf '%s : FCOPTIM := $(subst -O2,-O1,$(FCOPTIM))\n' "$obj" >> "$cfg"
    done
  fi

  local old_str="${old_objs[*]:-}"
  local new_str="${new_objs[*]:-}"
  if [ "$old_str" != "$new_str" ]; then
    local changed_objs=()
    for obj in "${old_objs[@]}"; do
      if [[ ! " ${new_objs[*]:-} " =~ [[:space:]]"$obj"[[:space:]] ]]; then
        changed_objs+=("$obj")
      fi
    done
    for obj in "${new_objs[@]}"; do
      if [[ ! " ${old_objs[*]:-} " =~ [[:space:]]"$obj"[[:space:]] ]]; then
        changed_objs+=("$obj")
      fi
    done
    for obj in "${changed_objs[@]}"; do
      find "$target_dir" -name "$obj" -delete 2>/dev/null || true
    done
  fi

  O1_INFO="$md5 ($count files)"
}

if [ "${1:-}" = "--apply-o1" ]; then
  shift
  cfg=${1:?usage: build.sh --apply-o1 <configure.wrf> [mode]}
  bmode=${2:-cpu-ref}
  apply_o1_list "$cfg" "$bmode"
  echo "o1 files: $O1_INFO"
  exit 0
fi

if [ -n "${O1_LIST:-}" ] && [ "$O1_LIST" != none ]; then
  O1_LIST=$(realpath "$O1_LIST" 2>/dev/null || readlink -f "$O1_LIST" || echo "$O1_LIST")
fi

mode=${1:?usage: build.sh <cpu-ref|gpu-repro|gpu-debug|gnu>[-fine] [--commit REV|--worktree] [--clean] [--fire-ideal] [--fine] [--uninit nan|zero] [--tag T]}
shift
src=commit; rev=HEAD; clean=0; fire=0; tag=; fine=0; uninit=
case $mode in *-fine) mode=${mode%-fine}; fine=1 ;; esac
while [ $# -gt 0 ]; do
  case $1 in
    --commit) src=commit; rev=${2:?}; shift ;;
    --worktree) src=worktree ;;
    --clean) clean=1 ;;
    --fire-ideal) fire=1 ;;
    --fine) fine=1 ;;
    --uninit) uninit=${2:?}; shift ;;
    --tag) tag=${2:?}; shift ;;
    *) die "unknown option $1" ;;
  esac
  shift
done
[ $fine = 1 ] && tag=fine${tag:+-$tag}
if [ -n "$uninit" ]; then
  [[ $mode == gnu* ]] || die "--uninit is for gnu builds (T-UNINIT)"
  case $uninit in nan|zero) ;; *) die "--uninit nan|zero" ;; esac
  tag=${tag:+$tag-}uninit-$uninit
fi
if [[ $mode == gnu* ]] && [ -x "${NETCDF_GNU:-$DEPS/netcdf-gnu}/bin/nf-config" ]; then NETCDF=${NETCDF_GNU:-$DEPS/netcdf-gnu}; fi
case $mode in
  cpu-ref)   stanza="GPU port CPU-REF";   kind=dmpar ;;
  gpu-repro) stanza="GPU port GPU-REPRO"; kind=dmpar ;;
  gpu-debug) stanza="GPU port GPU-DEBUG"; kind=dmpar ;;
  gnu|gnu-ref|gnu-gpu) stanza="GNU (gfortran/gcc)"; kind=serial ;;
  *) die "unknown mode $mode" ;;
esac

if [ $src = commit ]; then
  sha=$(git -C "$PORT_REPO" rev-parse --verify "$rev^{commit}") || die "no commit $rev"
  out=$WORK/builds/$mode/${sha:0:12}${tag:+-$tag}
  if [ -x "$out/main/wrf.exe" ] && [ -f "$out/BUILD_INFO" ] && [ $clean = 0 ]; then
    note "build exists: $out"; echo "$out"; exit 0
  fi
  rm -rf "${out:?}"; mkdir -p "$out"
  git -C "$PORT_REPO" archive "$sha" WRF | tar -x -C "$out" --strip-components=1
  # commits before the port's stanzas: take configure.defaults from HEAD
  grep -q "GPU port CPU-REF" "$out/arch/configure.defaults" || \
    git -C "$PORT_REPO" show HEAD:WRF/arch/configure.defaults > "$out/arch/configure.defaults"
  source_desc="commit $sha"
else
  out=$WORK/builds/$mode/worktree${tag:+-$tag}
  [ $clean = 1 ] && rm -rf "${out:?}"
  mkdir -p "$out"
  # copy only files whose content changed; copied files get a new mtime, so make rebuilds them
  ncopied=$(python3 "$HERE_H100/sync_tree.py" "$PORT_REPO/WRF" "$out")
  note "$ncopied changed source files copied into $out"
  head=$(git -C "$PORT_REPO" rev-parse HEAD)
  git -C "$PORT_REPO" diff HEAD -- WRF > "$out/worktree.diff" || true
  source_desc="worktree: HEAD $head + uncommitted diff md5 $(md5sum < "$out/worktree.diff" | cut -c1-12) (worktree.diff)"
fi
cd "$out"

if [ ! -f configure.wrf ]; then
  line=$(x bash -c "NETCDF=$NETCDF ./configure < /dev/null 2>/dev/null" | grep -F "$stanza" | head -1) || true
  [ -n "$line" ] || die "configure does not offer '$stanza' (NETCDF=$NETCDF; is the compiler in PATH?)"
  opt=$(echo "$line" | sed -E "s/.* ([0-9]+)\. \($kind\).*/\1/")
  [[ $opt =~ ^[0-9]+$ ]] || die "cannot find the ($kind) option in: $line"
  x bash -c "printf '%s\n1\n' $opt | NETCDF=$NETCDF ./configure > configure.log 2>&1" || die "configure failed ($out/configure.log)"
  [ -f configure.wrf ] || die "configure wrote no configure.wrf ($out/configure.log)"
  echo "$opt" > .configure_option
  if [ -n "$uninit" ]; then
    # T-UNINIT: initialize every local to signaling NaN or to zero (as port/ccr/t_uninit.sh)
    if [ $uninit = nan ]; then fl="-finit-real=snan -finit-integer=-8388607 -finit-logical=true"
    else fl="-finit-real=zero -finit-integer=0 -finit-logical=false"; fi
    base=$(sed -n 's/^FCBASEOPTS_NO_G *= *//p' configure.wrf | head -1)
    sed -i "s/^\(FCBASEOPTS_NO_G *=.*\)$/\1 $fl/" configure.wrf
    # routines with a bare SAVE statement: gfortran rejects -finit-* there (not used by the case)
    printf 'module_mp_morr_two_moment_aero.o : FCBASEOPTS_NO_G = %s\n' "$base" >> configure.wrf
  fi
  if [[ $mode == gnu-ref || $mode == gnu-gpu ]]; then
    # gfortran views for code checks without NVHPC (CODE_ONLY.md section 7); same arithmetic flags in both
    defs="-DREPRO_MATH -DWRF_POOL"; fopt=-frecursive
    [ $mode = gnu-gpu ] && { defs="$defs -DWRF_GPU"; fopt="-fopenacc -frecursive"; }
    sed -i -E "/^ARCH_LOCAL[[:space:]]*=/ s/\$/ $defs/" configure.wrf
    sed -i -E "/^FCBASEOPTS_NO_G[[:space:]]*=/ s/\$/ $fopt/" configure.wrf
    sed -i -E "/^LDFLAGS_LOCAL[[:space:]]*=/ s/\$/ $fopt/" configure.wrf
    grep -q -- "$fopt" configure.wrf || die "could not add $fopt to configure.wrf"
  fi
  if [ $fine = 1 ]; then
    # fine tracing: only a preprocessor macro; the arithmetic flags stay (check_build_flags.py)
    sed -i -E '/^ARCH_LOCAL[[:space:]]*=/ { /-DWRF_TRACE_FINE/! s/$/ -DWRF_TRACE_FINE/ }' configure.wrf
    grep -q -- '-DWRF_TRACE_FINE' configure.wrf || die "could not add -DWRF_TRACE_FINE to configure.wrf"
  fi
fi

# NVHPC 25.9, 26.1, 26.5: fort2 crashes (signal 11) on 11 files at -O2 (FIX_LEDGER F-08).
# Compiled at -O1 instead, in every nvfortran build alike. List from $O1_LIST (default o1_files.txt;
# O1_LIST=none turns it off). Idempotent; deletes .o of affected files if the list changes.
apply_o1_list configure.wrf "$mode"

rm -f main/wrf.exe
stamp=$(date +%s)
note "compiling $mode in $out (log: compile.log)"
x bash -c "NETCDF=$NETCDF J='-j $BUILD_JOBS' ./compile em_real > compile.log 2>&1" || true
if [ ! -x main/wrf.exe ]; then
  grep -n -i -E "error|fatal" compile.log | grep -v -i "werror\|error_fatal\|errmsg\|Error.o\|_error" | head -40 >&2
  die "build failed, see $out/compile.log"
fi
if [ $fire = 1 ]; then
  cp main/wrf.exe main/wrf_real.exe
  x bash -c "NETCDF=$NETCDF J='-j $BUILD_JOBS' ./compile em_fire > compile_fire.log 2>&1" || true
  [ -x main/ideal.exe ] || die "em_fire ideal.exe failed ($out/compile_fire.log)"
  mv main/ideal.exe main/ideal_fire.exe
  mv main/wrf_real.exe main/wrf.exe
fi
{
  echo "mode: $mode$([ $fine = 1 ] && echo -fine)"
  echo "source: $source_desc"
  echo "configure: option $(cat .configure_option) ($stanza, $kind)"
  echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ) on $(hostname)"
  echo "machine: $(machine_line)"
  echo "build jobs: $BUILD_JOBS"
  echo "compiler: $(x bash -c 'case '"$mode"' in gnu*) gfortran --version;; *) nvfortran --version;; esac' 2>/dev/null | grep -v '^$' | head -2 | tr '\n' ' ')"
  echo "wrf.exe md5: $(md5sum < main/wrf.exe | cut -d' ' -f1)"
  echo "o1 files: $O1_INFO"
  [ "${CONTAINER:-none}" != none ] && [ -n "${IMAGE:-}" ] && [ -f "$IMAGE" ] && echo "image: $IMAGE sha256 $(sha256sum < "$IMAGE" | cut -d' ' -f1)"
} > BUILD_INFO
cat BUILD_INFO >&2
# remember the exact compile commands of this build (for compile_one.sh and harness.sh)
python3 "$HERE_H100/build_cmds.py" update "$out" >&2 || note "build_cmds.py update failed (compile_one.sh/harness.sh need it)"
echo "$out"
