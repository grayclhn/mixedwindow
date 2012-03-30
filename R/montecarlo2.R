## seed, jjob, dbtable, and nsim are set in the file MakeScript.R
## for debugging:
## seed <- 1; jjob <- 1; dbtable <- "temp"; nsim <- 3
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

mcdesign <- expand.grid(P = c(40, 80, 120, 160), R = c(80, 120),
                        isPower = c(FALSE, TRUE))

## really basic function to generate our data; this could be written
## much better.
rdgp <- function(n, isPower, nburn = 1600) {
  ## The processes are
  ## y_t = a %*% c(1, y_{t-1}, z_{t-1},...,z_{t-4}) + e1
  ## z_t = b %*% c(z_{t-1},...,z_{t-4}) + e2
  ## with 
  ## (e1, e2) ~ N(0, v)
  a <- c(2.237, 0.261, isPower * c(3.363, -0.633, -0.377, -0.529))
  b <- c(0, 0, 0.804, -0.221, 0.226, -0.205)
  v <- matrix(c(10.505, 1.036, 1.036, 0.366), 2)

  ntot <- n + nburn
  ret <- nburn + (5:n)
  ## we're going to let x_t = (y_t, z_t); draw from the stationary
  ## distribution and then populate the rest of the matrix with the
  ## innovations.
  x <- mvrnorm(ntot, c(0,0), v)
  A <- rbind(a, b)
  for (i in 5:ntot) {
    x[i,] = c(A %*% c(1, x[i-1,], x[i - (2:4),2]) + x[i,])
  }
  
  data.frame(y = x[ret, 1], y1 = x[ret-1,1], z1 = x[ret-1, 2],
             z2 = x[ret-2, 2], z3 = x[ret-3, 2], z4 = x[ret-4, 2])
}

null <- function(d) lm(y ~ y1, data = d)
alt <- function(d) lm(y ~ y1 + z1 + z2 + z3 + z4, data = d)
xfn <- function(d) as.matrix(cbind(1, d[,"y1",drop=FALSE]))
yfn <- function(d) as.matrix(d[,"y", drop = FALSE])
  
for (r in rows(mcdesign)) {
  print(r)
  insert(mcdata) <-
    data.frame(r, t(replicate(nsim, {
      d <- with(r, rdgp(R + P, isPower))
      cals <- calstat(d, r$R, null, alt, xfn, yfn)
      c(pOld = oos.t(null, alt, d, r$R, method = "ClW:07", conf.level = .9)$p.value,
        pNew1 = cals[1], pNew2 = cals[2])
    })), row.names = seq_len(nsim))
}
