# Copyright (c) 2011-2015 Gray Calhoun.

gitfiles := .gitignore .gitmodules
version := $(shell git describe --tags --abbrev=0)
zipfile := calhoun-mixedwindow-$(version).zip
pdffile := calhoun-mixedwindow-$(version).pdf
files := $(filter-out $(gitfiles), $(shell git ls-tree --full-tree -r --name-only HEAD)) \
  $(foreach d,dbframe-R-library texextra oosanalysis-R-library, \
    $(addprefix $d/,$(filter-out $(gitfiles), $(shell git -C $d ls-tree --full-tree -r --name-only HEAD))))

.PHONY: all clean burn libs dirs zip VERSION.tex
all: $(pdffile) $(zipfile)

.DELETE_ON_ERROR:
.INTERMEDIATE: mixedwindow.pdf

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash

zip: $(zipfile)
$(zipfile): $(files)
	zip $@ $(files)

dirs: tex db
tex db:
	mkdir -p $@

tex/ap.tex: R/ap.R
tex/mcDef.tex: R/mcTex.R R/mcSetup.R
tex/mc1.tex: R/mc1Table.R mc1
tex/mc2.tex: R/mc2Table.R mc2
tex/ap.tex tex/mcDef.tex tex/mc1.tex tex/mc2.tex: | tex
	$(Rscript) $(RSCRIPTFLAGS) $< &> $<out

mc1_dummies = $(foreach i, $(shell echo {1..6}), mc1db$i)
mc2_dummies = $(foreach i, $(shell echo {1..6}), mc2db$i)
mc1: $(addprefix db/, $(mc1_dummies))
mc2: $(addprefix db/, $(mc2_dummies))

$(addprefix db/,$(mc1_dummies)): R/mc1.R | db
	echo 'jjob <- $(patsubst db/mc1db%,%,$@);' | cat - $< | $(Rscript) $(RSCRIPTFLAGS) - &> $@.log
	touch $@

$(addprefix db/,$(mc2_dummies)): R/mc2.R | db
	echo 'jjob <- $(patsubst db/mc2db%,%,$@);' | cat - $< | $(Rscript) $(RSCRIPTFLAGS) - &> $@.log
	touch $@

mc1 mc2:
	echo "$(foreach d, $^, attach database '$d.db' as $(notdir $d);)"\
	     "drop table if exists main.$@;"\
	     "create table main.$@ as select * from $(notdir $<).$@;" \
	     "$(foreach d, $(notdir $(filter-out $<,$^)), insert into main.$@ select * from $d.$@;)"\
	     "$(foreach d, $^, detach database '$(notdir $d');)"\
	  | $(sqlite) data/mcdata.db
	touch $@

$(pdffile): mixedwindow.pdf
	cp $< $@

results = mixedwindow_thm1.tex mixedwindow_lem2.tex mixedwindow_thm3.tex
# 3/14/2013: removing the dependency on the second monte carlo since I don't
# think it's important for the main points of the paper.
mixedwindow.pdf: tex/mc1.tex tex/mcDef.tex tex/ap.tex # tex/mc2.tex
mixedwindow.pdf: %.pdf: %.tex VERSION.tex $(results)
	$(latexmk) $(LATEXMKFLAGS) $<

VERSION.tex:
	echo "\newcommand\VERSION{$$(texextra/version_git.sh)}" > $@

clean: 
	$(latexmk) -c mixedwindow.tex
	rm -f *~ slides/*~ data/*~
burn: clean
	$(latexmk) -C mixedwindow.tex
	rm -rf R auto floats tex db mc1 mc2 slides/*.tex data/mcdata.db lib 

ROPTS = --byte-compile
libs: 
	mkdir -p lib/oosanalysis.Rcheck lib/dbframe.Rcheck
	R CMD check -o lib/oosanalysis.Rcheck oosanalysis-R-library
	R CMD INSTALL $(ROPTS) --library=lib oosanalysis-R-library
	R CMD check -o lib/dbframe.Rcheck dbframe-R-library
	R CMD INSTALL $(ROPTS) --library=lib dbframe-R-library
