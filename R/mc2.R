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
mcdesign <- expand.grid(P = c(40, 80, 120, 160), R = c(80, 120),
			simulationtype = c("0.size", "1.power"),
			stringsAsFactors = FALSE)

library(dbframe, lib.loc = "lib")
library(oosanalysis, lib.loc = "lib")
library(rlecuyer)

.lec.SetPackageSeed(c(819, 3475, 9090, 75139, 78599, 67))
jobnames <- LETTERS[1:6]
.lec.CreateStream(jobnames)
.lec.CurrentStream(jobnames[jjob])

null1 <- function(d) lm(y ~ yL1, data = d)
null2 <- function(d) lm(y ~ yL1 + yL2 + yL3 + yL4, data = d)
alt1 <-  function(d) lm(y ~ yL1 + zL1 + zL2 + zL3 + zL4, data = d)
alt2 <-  function(d) lm(y ~ yL1 + yL2 + yL3 + yL4 + zL1 + zL2 + zL3 + zL4, 
                        data = d)

generate.data.mc2 <- function(nobs, simulationtype, nburn = 1000) {
  gammastar <- switch(simulationtype,
                      "0.size" = rep(0, 4),
                      "1.power" = c(3.363, -0.633, -0.377, -0.529))
  return(rvar(nobs, list(y = c(0.261, rep(0, 3), gammastar),
                         z = c(rep(0, 4), c(0.804, -0.221, 0.226, -0.205))),
              c(2.237, 0), matrix(c(10.505, 1.036, 1.036, 0.366), 2)))
}

mcdata <- dbframe("mc2", dbdriver = "SQLite",
		  dbname = sprintf("db/mc2db%d.db", jjob), clear = TRUE)

for (r in rows(mcdesign)) {
  print(r)
  insert(mcdata) <- data.frame(r, row.names = NULL,
    t(replicate((nsims %/% 6 + (jjob <= nsims %% 6)), {
      randomdata <- with(r, generate.data.mc2(R + P, simulationtype))
      c(clarkwestrolling1 = clarkwest(null1, alt1, randomdata, r$R, window = "rolling")$pvalue,
	clarkwestrecursive1 = clarkwest(null1, alt1, randomdata, r$R, window = "recursive")$pvalue,
	mixed1 = mixedwindow(null1, alt1, randomdata, r$R, window = "rolling")$pvalue,
	clarkwestrolling2 = clarkwest(null2, alt2, randomdata, r$R, window = "rolling")$pvalue,
	clarkwestrecursive2 = clarkwest(null2, alt2, randomdata, r$R, window = "recursive")$pvalue,
	mixed2 = mixedwindow(null2, alt2, randomdata, r$R, window = "rolling")$pvalue)})))
}
