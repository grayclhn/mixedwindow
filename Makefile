.PHONY: all clean burn libs
all: Paper.pdf zip

.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent

tex/empiricalresults.tex: R/empirics.R
	mkdir -p $(@D)
	$(Rscript) $(RSCRIPTFLAGS) $< &> $<out

mc1_dummies = $(foreach i, $(shell echo {1..6}), mc1db$i)
mc2_dummies = $(foreach i, $(shell echo {1..6}), mc2db$i)
mc1: $(addprefix db/, $(mc1_dummies))
mc2: $(addprefix db/, $(mc2_dummies))

$(addprefix db/,$(mc1_dummies)): R/montecarlo.R
	mkdir -p $(@D)
	echo 'jjob <- $(patsubst db/mc1db%,%,$@);' | cat - $< \
	                                 | $(Rscript) $(RSCRIPTFLAGS) - &> $@.log
	touch $@

$(addprefix db/,$(mc2_dummies)): R/montecarlo2.R
	mkdir -p $(@D)
	echo 'jjob <- $(patsubst db/mc2db%,%,$@);' | cat - $< \
	                                 | $(Rscript) $(RSCRIPTFLAGS) - &> $@.log
	touch $@

mc1 mc2:
	echo "$(foreach d, $^, attach database '$d.db' as $(notdir $d);)"\
	     "drop table if exists main.$@;"\
	     "create table main.$@ as select * from $(notdir $<).$@;" \
	     "$(foreach d, $(notdir $(filter-out $<,$^)), insert into main.$@ select * from $d.$@;)"\
	     "$(foreach d, $^, detach database '$(notdir $d');)"\
	  | $(sqlite) data/mcdata.db
	touch $@

floats/simulation1.tex: R/simulationtable1.R mc1
floats/simulation2.tex: R/simulationtable2.R mc2
floats/simulation1.tex floats/simulation2.tex:
	mkdir -p $(@D)
	$(Rscript) $(RSCRIPTFLAGS) $< &> $<out

Paper.pdf: Paper.tex floats/simulation1.tex tex/empiricalresults.tex \
	          floats/simulation2.tex tex/simulationdefinitions.tex \
	          tex/empiricsdefinitions.tex VERSION
	$(latexmk) $(LATEXMKFLAGS) $< && $(latexmk) $(LATEXMKFLAGS) -c $<

archfile = calhoun-2011-mixedwindow.tar.gz
zip: $(archfile)
$(archfile): $(filter-out .gitignore conference-stuff/ slides/, \
	                          $(shell git ls-tree HEAD -r --name-only)) \
	            Paper.pdf texextra/AllRefs.bib
	tar chzf $@ $^

clean: 
	rm -f *~ *.aux *.bbl *.blg *.fdb_latexmk *.log *.lot *.out *.toc \
	             *.ttt *.dvi slides/*~ data/*~
burn: clean
	rm -rf R auto floats tex db mc1 mc2 slides/*.tex data/mcdata.db \
	              *.pdf *.gz 

ROPTS = --byte-compile
libs: 
	mkdir -p lib/oosanalysis.Rcheck lib/dbframe.Rcheck
	R CMD check -o lib/oosanalysis.Rcheck oosanalysis-R-library
	R CMD INSTALL $(ROPTS) --library=lib oosanalysis-R-library
	R CMD check -o lib/dbframe.Rcheck dbframe-R-library
	R CMD INSTALL $(ROPTS) --library=lib dbframe-R-library
