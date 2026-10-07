# The book: WRF and WRF-Fire on GPUs

A LaTeX textbook that grows with the port. It describes WRF's dynamics and physics, WRF-Fire and CFBM, WRF's software
architecture, and the GPU port: reproducibility, OpenMP offload, the phases, performance.

## Build

```sh
cd book && make          # latexmk -pdf; needs TeX Live with the packages listed in preamble.tex
```

- **CI:** `.github/workflows/book.yml` builds the PDF on every push that changes `book/`, and keeps it as a workflow
  artifact (`wrf-gpu-book`).
- **Cloud coding environment:** it cannot build the book. It has no TeX installation, and the TeX package servers are
  blocked by its network policy. Use the CI artifact there.

## Status

| Chapter | File | State |
|---|---|---|
| Preface, 1 Introduction, 2 The case | `chapters/00-02` | draft |
| 3–14 Model, physics, fire, architecture | `chapters/03-14` | outline (cards B-03 ... B-14) |
| 15 Floating-point reproducibility | `chapters/15-reproducibility.tex` | draft (card B-15 completes it) |
| 16–20 GPUs, the port, performance, multi-GPU, versions | `chapters/16-20` | outline (cards B-16 ... B-20) |
| Appendices | `chapters/A-kernels.tex`, `B-namelist.tex` | outline (card B-21) |

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
