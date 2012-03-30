## seed, jjob, dbtable, and nsim are set in the file MakeScript.R
## for debugging:
## seed <- 1; jjob <- 1; dbtable <- "temp"; nsim <- 3
nsim <- 100
set.seed(seed)
set.seed(sample(1:10000000, jjob)[jjob],
         kind = 'Mersenne-Twister', normal.kind = 'Inversion')

source("R/mcsetup.R")
library(MASS)
library(OOS)
library(dbframe)

mcdata <- dbframe(dbtable, paste("db/", dbtable, jjob, ".db", sep = ""),
                  overwrite = TRUE)
clear(mcdata)

mcdesign <- expand.grid(P = 10000, R = 20)

## really basic function to generate our data; this could be written
## much better.
rdgp <- function(n) {
  y  <- rnorm(n)
  x1 <- rnorm(n)
  x2 <- rnorm(n)
  data.frame(y, x1, x2)
}

null <- function(d) lm(y ~ 1, data = d)
alt <- function(d) lm(y ~ x1 + x2, data = d)
xfn <- function(d) matrix(1, nrow(d))
yfn <- function(d) as.matrix(d[,"y", drop = FALSE])
  
for (r in rows(mcdesign)) {
  print(r)
  insert(mcdata) <-
    data.frame(r, t(replicate(nsim, {
      d <- with(r, rdgp(R + P))
      cals <- calstat(d, r$R, null, alt, xfn, yfn)
      c(pOld = oos.t(null, alt, d, r$R, method = "ClW:07", conf.level = .9)$p.value,
        pNew1 = cals[1], pNew2 = cals[2])
    })), row.names = seq_len(nsim))
}
