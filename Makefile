.PHONY: all clean burn libs dirs
all: Paper.pdf

.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash

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

# 3/14/2013: removing the dependency on the second monte carlo since I don't
# think it's important for the main points of the paper.
Paper.pdf: Paper.tex tex/mc1.tex tex/mcDef.tex tex/ap.tex # tex/mc2.tex
	$(latexmk) $(LATEXMKFLAGS) $< && $(latexmk) $(LATEXMKFLAGS) -c $<

clean: 
	$(latexmk) -c Paper.tex
	rm -f *~ slides/*~ data/*~
burn: clean
	$(latexmk) -C Paper.tex
	rm -rf R auto floats tex db mc1 mc2 slides/*.tex data/mcdata.db lib 

ROPTS = --byte-compile
libs: 
	mkdir -p lib/oosanalysis.Rcheck lib/dbframe.Rcheck
	R CMD check -o lib/oosanalysis.Rcheck oosanalysis-R-library
	R CMD INSTALL $(ROPTS) --library=lib oosanalysis-R-library
	R CMD check -o lib/dbframe.Rcheck dbframe-R-library
	R CMD INSTALL $(ROPTS) --library=lib dbframe-R-library
