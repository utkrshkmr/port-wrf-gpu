# Build the book: make (needs latexmk and a TeX Live with the packages of preamble.tex)
TEX := $(wildcard *.tex chapters/*.tex)

all: main.pdf

main.pdf: $(TEX) refs.bib
	latexmk -pdf -interaction=nonstopmode -halt-on-error main.tex

clean:
	latexmk -C main.tex

.PHONY: all clean
