## seed, jjob, dbtable, and nsim are set in the file mc-setup.R
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

mcdesign <- expand.grid(P = c(120, 240, 360, 720), R = c(120, 240),
                        isPower = c(FALSE, TRUE))


## really basic function to generate our data; this could be written
## much better.
rdgp <- function(n, isPower) {
  ## The processes are
  ## y_t = a %*% c(1, z_{t-1}) + e1
  ## z_t = b %*% c(1, z_{t-1}) + e2
  ## with 
  ## (e1, e2) ~ N(0, v)
  gam <- 0.35 * isPower
  a <- c(.5, gam)
  b <- c(.15, .95)
  v <- matrix(c(18, -.5, -.5, .025), 2)
  
  Ez <- b[1] / (1 - b[2])
  Ey <- a[1] + a[2] * Ez

  ## elements of the variance-covariance matrix
  Vz <- v[2,2] / (1 - b[2]^2)
  Vy <- v[1,1] + gam^2 * Vz
  Cyz <- a[2] * b[2] * Vz + v[1,2]

  ## we're going to let x_t = (y_t, z_t); draw from the stationary
  ## distribution and then populate the rest of the matrix with the
  ## innovations.
  x <- rbind(mvrnorm(1, c(Ey, Ez), matrix(c(Vy, Cyz, Cyz, Vz), 2)),
             mvrnorm(n, c(0,0), v))
  A <- matrix(c(0, 0, a[2], b[2]), 2)
  for (i in 1 + (1:n)) {
    x[i,] = drop(c(a[1], b[1]) + A %*% x[i-1,] + x[i,])
  }
  data.frame(y = x[-1,1], zlag = x[-n,2])
}

null <- function(d) lm(y ~ 1, data = d)
alt <- function(d) lm(y ~ zlag, data = d)
xfn <- function(d) matrix(1, nrow(d))
yfn <- function(d) as.matrix(d[,"y", drop = FALSE])
  
for (r in rows(mcdesign)) {
  print(r)
  insert(mcdata) <-
    data.frame(r, t(replicate(nsim, {
      d <- with(r, rdgp(R + P, isPower))
      cals <- calstat(d, r$R, null, alt, xfn, yfn)
      c(pOld = oos.t(null, alt, d, r$R, method = "ClW:07", conf.level = .9)$p.value,
        pNew = cals)
    })), row.names = seq_len(nsim))
}
