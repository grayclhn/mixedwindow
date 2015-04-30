## Copyright (c) 2011-2015 Gray Calhoun.

source("R/mcSetup.R")
library(dbframe, lib.loc = "lib")
mcdata2 <- dbframe("mc2", dbdriver = "SQLite",
		   dbname = "data/mcdata.db", readonly = TRUE)

## Removed this code on 3 March 2013; the second simulation is very
## similar to the first, so I'll only present the first set of sims.

## colsql <- lapply(1:2, function(i) {
##   c("'Sim. type'" =
##       sprintf("case when simulationtype = '0.size' then 'size %d'
##                     else 'power %d' end", i, i),
##     R = "R", P = "P",
##     "'Pr[CW~roll.]'" =
##       sprintf("100 * avg(clarkwestrolling%d <= %f)", i, testsize),
##     "'Pr[CW~rec.]'" =
##       sprintf("100 * avg(clarkwestrecursive%d <= %f)", i, testsize),
##     "'Pr[new]'" = sprintf("100 * avg(mixed%d <= %f)", i, testsize))
## })
    
## summary <- lapply(colsql, function(cs)
##                   select(mcdata2, cs,
##                          group.by = c("simulationtype", R = "R", P = "P")))
## summary <- do.call(rbind, summary)

colsql <- c("'Sim. type'" =
            "case when simulationtype = '0.size' then 'size' else 'power' end",
            R = "R", P = "P",
            "'Pr[CW~roll.]'" =
            sprintf("100 * avg(clarkwestrolling1 <= %f)", testsize),
            "'Pr[CW~rec.]'" =
            sprintf("100 * avg(clarkwestrecursive1 <= %f)", testsize),
            "'Pr[new]'" = sprintf("100 * avg(mixed1 <= %f)", testsize))

summary <- select(mcdata2, colsql, group.by = c("simulationtype", R = "R", P = "P"))

cat(file = "tex/mc2.tex",
    booktabs(summary[,-1],
             digits = c(rep(0,3), rep(1,3)), align = c("l", rep("C", 5)),
             purgeduplicates = c(rep(TRUE, 3), rep(FALSE, 3)),
	     numberformat = c(FALSE, rep(TRUE, 5))))
