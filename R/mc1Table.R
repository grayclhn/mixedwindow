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
