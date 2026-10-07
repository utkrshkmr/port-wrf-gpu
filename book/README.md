# The book: WRF and WRF-Fire on GPUs

A LaTeX textbook that grows with the port. It describes WRF's dynamics and physics, WRF-Fire and CFBM, WRF's software
architecture, and the GPU port: GPU architecture, OpenACC and CUDA Fortran, reproducibility, the porting method, and
performance on A100 and H100 (profiling, models, fusion, caching, tiling, warp-level work, column physics). The plan
of the book is [roadmap/plan-book.md](../roadmap/plan-book.md).

## Build

```sh
cd book && make          # latexmk -pdf; needs TeX Live with the packages listed in preamble.tex
```

- **CI:** `.github/workflows/book.yml` builds the PDF on every push that changes `book/`, and keeps it as a workflow
  artifact (`wrf-gpu-book`).
- **Cloud coding environment:** it cannot build the book. It has no TeX installation, and the TeX package servers are
  blocked by its network policy. Use the CI artifact there.

## Status

All 40 chapters and 6 appendices are written (8 parts). What remains is measured results: every number the port has
not measured yet is printed as "(to be reported)" (`\tbr`), and is filled in from `port/RESULTS.md`, `port/PERF.md`
and `perf/` as the gates pass.

| Part | Chapters | File | State |
|---|---|---|---|
| Front | Preface | `chapters/00-preface.tex` | written |
| I The WRF ecosystem | 1-4 | `chapters/01-04` | written |
| II The ARW dynamical core | 5-10 | `chapters/05-10` | written |
| III Physics | 11-18 | `chapters/11-18` | written |
| IV Fire | 19-21 | `chapters/19-21` | written |
| V Software | 22-24 | `chapters/22-24` | written |
| VI GPUs and the port | 25-29 | `chapters/25-29` | written; device results to be reported |
| VII Performance on A100 and H100 | 30-38 | `chapters/30-38` | written; measurements to be reported (chapter 37 is the results table) |
| VIII Evolution | 39-40 | `chapters/39-40` | written |
| Appendices | A-F | `chapters/A-F*.tex` | written; A is generated (`tools/kernels_tex.py`) |

Open items:
- the bibliography (`refs.bib`) is not yet checked against the publishers (card B-02);
- the figures of measured data (roofline points, time per range) wait for the profiler's database (plan-profiler
  PR-L5.3);
- Appendix A must be regenerated whenever `port/agent/kernels.csv` changes:
  `python3 book/tools/kernels_tex.py` (`--check` reports whether it is current).

## Rules for writing a chapter (track B of roadmap/BACKLOG.md)

- Write from the code and the cited sources. Every equation names the routine that implements it:
  `\src{dyn_em/module_small_step_em.F}{advance_w}`. Write code names with `\code{...}`; underscores need no escaping
  there.
- Cite only entries of `refs.bib`, and check new entries against the publisher. The file says which entries are
  checked.
- Numbers about the port (tests, timings) come from `port/RESULTS.md`, `port/PERF.md` or `perf/reports/`, with the
  source named. Numbers not yet measured are announced as "to be reported", never invented.
- Keep the source ASCII apart from accents. Use LaTeX for symbols (`$\le$`, `$\to$`).
- Replace a chapter's `outline` box when the chapter is written. Use `portnote` boxes for implementation remarks and
  `keypoint` for the one thing to remember.
- A chapter is done when CI builds the book without errors or undefined references.
