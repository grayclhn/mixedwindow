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
mcdesign <- expand.grid(P = c(120, 240, 360, 720), R = c(120, 240),
                        simulationtype = c("0.size", "1.stable", "2.breaks"),
                        stringsAsFactors = FALSE)

library(dbframe, lib.loc = "lib")
library(oosanalysis, lib.loc = "lib")
library(rlecuyer)

.lec.SetPackageSeed(c(89, 7345, 0909, 17593, 8759, 76))
jobnames <- LETTERS[1:6]
.lec.CreateStream(jobnames)
.lec.CurrentStream(jobnames[jjob])

null <- function(d) lm(y ~ 1, data = d)
alt <- function(d) lm(y ~ zL1, data = d)

generate.data.mc1 <- function(nobs, simulationtype, nburn = 1000) {
  mean.gamma <- 0.35
  innovation.vcv <- matrix(c(18, -0.5, -0.5, 0.025), 2, 2)
  switch(simulationtype,
    "0.size"   = rvar(nobs, list(y = c(0, 0), z = c(0, 0.95)), 
                      c(0.5, 0.15), innovation.vcv),
    "1.stable" = rvar(nobs, list(y = c(mean.gamma, 0), z = c(0, 0.95)), 
                      c(0.5, 0.15), innovation.vcv),
    "2.breaks" = {prebreak.nobs <- floor(nobs / 2)
                  postbreak.nobs <- nobs - prebreak.nobs

                  prebreak.data <- rvar(prebreak.nobs, list(y = c(0, 0), z = c(0, .95)),
                                        c(0.5, 0.15), innovation.vcv)
                  postbreak.data <- rvar(postbreak.nobs, 
                                         list(y = c(2 * mean.gamma, 0), z = c(0, .95)),
                                         c(0.5, 0.15), innovation.vcv, nburn = 0,
                                         y0 = prebreak.data[prebreak.nobs,c("y", "z")])
                  rbind(prebreak.data, postbreak.data)})
}

mcdata <- dbframe("mc1", dbdriver = "SQLite", clear = TRUE,
		  dbname = sprintf("db/mc1db%d.db", jjob))

for (r in rows(mcdesign)) {
  print(r)
  insert(mcdata) <- data.frame(r, row.names = NULL,
    t(replicate((nsims %/% 6 + (jjob <= nsims %% 6)), {
      randomdata <- with(r, generate.data.mc1(R + P, simulationtype))
      c(clarkwestrolling = clarkwest(null, alt, randomdata, r$R, window = "rolling")$pvalue,
	clarkwestrecursive = clarkwest(null, alt, randomdata, r$R, window = "recursive")$pvalue,
	mixed = mixedwindow(null, alt, randomdata, r$R, window = "rolling")$pvalue)})))
}
