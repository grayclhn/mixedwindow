# Copyright (c) 2011-2015 Gray Calhoun.

source("R/mcSetup.R")
library(dbframe, lib.loc = "lib")
mcdata1 <- dbframe("mc1", dbdriver = "SQLite", dbname = "data/mcdata.db",
		   readonly = TRUE)

d <- select(mcdata1, c("'Sim. type'" = "case simulationtype
	                                when '0.size' then 'size'
		                        when '1.stable' then 'power (stable)'
		                        when '2.breaks' then 'power (breaks)' end",
                       R = "R", P = "P",
                       "'Pr[CW~roll.]'" =
                       sprintf("100 * avg(clarkwestrolling <= %f)", testsize),
                       "'Pr[CW~rec.]'" =
                       sprintf("100 * avg(clarkwestrecursive <= %f)", testsize),
                       "'Pr[new]'" = sprintf("100 * avg(mixed <= %f)", testsize)),
            group.by = c("simulationtype", R = "R", P = "P"))[,-1]

cat(file = "tex/mc1.tex",
    booktabs(d, purgeduplicates = c(rep(TRUE, 3), rep(FALSE, 3)),
	     numberformat = c(FALSE, rep(TRUE, 5)),
	     digits = c(0, 0, 0, 1, 1, 1), align = c("l", rep("C", 5))))
