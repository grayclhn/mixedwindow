# Copyright (c) 2011-2015 Gray Calhoun.

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
                                        c(-0.5, 0.15), innovation.vcv)
                  postbreak.data <- rvar(postbreak.nobs, 
                                         list(y = c(mean.gamma, 0), z = c(0, .95)),
                                         c(1.0, 0.15), innovation.vcv, nburn = 0,
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
	mixed = mixedwindow(null, alt, randomdata, r$R,
                            window = "rolling", pimethod = "theory")$pvalue)})))
}
