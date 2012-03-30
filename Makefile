# October 17, 2011
#
# Everything important is described by the files Makefile.mk1 and
# Makefile.mk2; they contain the lists of commands that put the paper
# together.  Makefile.mk2 is created by the R script Makefile.R;
# Makefile.R and Makefile.mk1 are both creted from Makefile.nw.  The
# file 'Makefile.pdf' has extensive documentation for the build
# process, and 'Simulations.pdf' has documentation for the Monte
# Carlo.  Assuming you have the right software installed, the command
# 'make' will run all of the commands necessary to create the final
# paper.  To better understand it, you may want to read the manual for
# GNU make, which is available online.
#
# -Gray Calhoun <gcalhoun@iastate.edu>

Rscript := Rscript
RFLAGS  := --vanilla

.PHONY: all
all: Paper.pdf Documentation.pdf

Makefile.mk: Documentation.nw
	notangle -t1 -R$@ $< | sed 's/^ /\t/' > $@

include Makefile.mk