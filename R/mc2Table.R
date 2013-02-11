# Copyright (c) 2011-2013 Gray Calhoun.

# This program is free software: you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation, either version 3 of the License, or (at your option) any later 
# version.

# This program is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more 
# details.

# You should have received a copy of the GNU General Public License along with 
# this program.  If not, see <http://www.gnu.org/licenses/>.

source("R/mcSetup.R")
library(dbframe, lib.loc = "lib")
mcdata2 <- dbframe("mc2", dbdriver = "SQLite",
		   dbname = "data/mcdata.db", readonly = TRUE)

colsql <- lapply(1:2, function(i) {
  c("'Sim. type'" =
      sprintf("case when simulationtype = '0.size' then 'size %d'
                    else 'power %d' end", i, i),
    R = "R", P = "P",
    "'Pr[\\textsc{cw}~roll.]'" =
      sprintf("100 * avg(clarkwestrolling%d <= %f)", i, testsize),
    "'Pr[\\textsc{cw}~rec.]'" =
      sprintf("100 * avg(clarkwestrecursive%d <= %f)", i, testsize),
    "'Pr[new]'" = sprintf("100 * avg(mixed%d <= %f)", i, testsize))
})
    
summary <- lapply(colsql, function(cs)
                  select(mcdata2, cs,
                         group.by = c("simulationtype", R = "R", P = "P"))[,-1])

cat(file = "tex/mc2.tex",
    booktabs(do.call(rbind, summary),
             digits = c(rep(0,3), rep(1,3)), align = c("l", rep("C", 5)),
             purgeduplicates = c(rep(TRUE, 3), rep(FALSE, 3)),
	     numberformat = c(FALSE, rep(TRUE, 5))))
