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
mcdata1 <- dbframe("mc1", dbdriver = "SQLite", dbname = "data/mcdata.db",
		   readonly = TRUE)
displaycols <-
  c("'Sim. type'" = "case simulationtype
		     when '0.size' then 'size'
		     when '1.stable' then 'power (stable)'
		     when '2.breaks' then 'power (breaks)' end",
    R = "R", P = "P",
    "'Pr[\\textsc{cw}~roll.]'" = sprintf("100 * avg(clarkwestrolling <= %f)", testsize),
    "'Pr[\\textsc{cw}~rec.]'" = sprintf("100 * avg(clarkwestrecursive <= %f)", testsize),
    "'Pr[new]'" = sprintf("100 * avg(mixed <= %f)", testsize))

cat(file = "tex/mc1.tex",
    booktabs(select(mcdata1, displaycols, group.by = c("simulationtype", "R", "P")),
	     purgeduplicates = c(rep(TRUE, 3), rep(FALSE, 3)),
	     drop = "simulationtype", numberformat = c(FALSE, rep(TRUE, 5)),
	     digits = c(0, 0, 0, 1, 1, 1), align = c("l", rep("C", 5))))
