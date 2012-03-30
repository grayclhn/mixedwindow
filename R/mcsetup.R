calstat <- function(d, R, null, alt, xfn, yfn) {
  n <- nrow(d)
  oos <- (R+1):n

  X <- xfn(d)
  pnull <- apply.oos(R, d, null, "recursive", "forecast")
  palt <- apply.oos(R, d, alt, "rolling", "forecast")
  r <- calmain(d, R, pnull, palt, yfn, xfn,
               solve(crossprod(X)/n,
                 colMeans(X[oos,,drop=FALSE] * c(pnull - palt))))
  unname(pnorm(r[1], 0, r[2], lower.tail = FALSE))
}

calmain <- function(d, R, pnull, palt, yfn, xfn = NULL, BF = NULL) {
  n <- nrow(d)
  oos <- (R+1):n
  P <- n - R
  Pi <- 1 - (R/P) * log(1 + P/R)
  
  Y <- c(yfn(d))

  enull <- Y[oos] - pnull
  ealt <- Y[oos] - palt
  
  f <- enull^2 - ealt^2 + (pnull - palt)^2

  if (is.null(xfn) | is.null(BF)) {
    sd <- sd(f)
  } else {
    X <- xfn(d)
    g <- enull * X[oos,,drop = FALSE] %*% BF

    S <- var(cbind(f, g))
    sd <- sqrt((S[1,1] + 2 * Pi * (S[1,2] + S[2,2])) / P)
  }
  c(mu = mean(f), sd = sd)
}

## this is what I want rbind to do for data frames
dstack <- function(...) {
  framelist <- list(...)
  cols <- unique(c(lapply(framelist, colnames), recursive = TRUE))
  do.call(rbind, lapply(framelist, function(d) {
    for (col in setdiff(cols, colnames(d))) d[,col] <- NA
    d[,cols]
  }))
}

## calculate the indices that give you a stationary bootstrap draw
iboot <- function(n, b) {
  series <- rep(NA, n)
  bootindex <- 1
  repeat {
    ##    obsindex <- 1 + (seq.int(sample(1:n, 1), length.out = rgeom(1, 1/b)) %% n)
    obsindex <- 1 + seq.int(sample(1:n,1), length.out = b) %% n
    if (length(obsindex) > 0) {
      bootend <- min(bootindex + length(obsindex) - 1, n)
      series[bootindex:bootend] <- obsindex[1:(bootend - bootindex + 1)]
      bootindex <- bootend + 1
      if (bootindex > n) break
    }
  }
  series
}

## use the stepdown procedure to test multiple models
caltest <- function(d, R, null, palt, yfn, xfn = NULL,
                    b, nboot, level = .05) {
  n <- nrow(d)
  oos <- (R+1):n
  pnull <- apply.oos(R, d, null, "recursive", "forecast")

  if (is.function(xfn)) {
    X <- xfn(d)
    B <- solve(crossprod(X)/n)
    oosstats <- sapply(palt, function(a) {
      stats <- calmain(d, R, pnull, a, yfn, xfn,
                       crossprod(B, colMeans(X[oos,,drop=FALSE] * (pnull - a))))
      stats[1] / stats[2]
    })
  } else {
    oosstats <- sapply(palt, function(a) {
      stats <- calmain(d, R, pnull, a, yfn)
      stats[1] / stats[2]
    })
  }
  
  boots <- as.matrix(calboot(d, R, null, palt, yfn, xfn, b, nboot)^2,
                     nrow = nboot)
  ## do the stepdown procedure
  reject <- rep(FALSE, length(oosstats))
  nreject.after <- 0
  nreject.before <- Inf
  ## repeat this until we stop rejecting models
  while ((nreject.after != nreject.before) &
         (nreject.after != length(reject))) {
    nreject.before <- nreject.after
    crit <- quantile(apply(boots[,!reject,drop=FALSE], 1, max), 1 - 2 * level)
    reject[oosstats^2 > crit & oosstats > 0] <- TRUE
    nreject.after <- sum(reject)
  }
  list(crit = crit, tstats = oosstats, rejected = oosstats[reject])
}

calboot <- function(d, R, null, palt, yfn, xfn, b, nboot) {
  n <- nrow(d)
  oos <- (R+1):n
  P <- n-R

  palt <- as.data.frame(palt)
  
  ## add the alternative forecasts to the data frame
  d[,names(palt)] <- NA
  d[oos,names(palt)] <- palt

  ## get the location parameter for the bootstrap distribution.
  pnullFull <- predict(null(d))[oos]
  y <- yfn(d[oos,])
  bootmean <- colMeans(c(y - pnullFull)^2 - (y - palt)^2 + (pnullFull - palt)^2)

  ## generate mean and variance via stationary bootstrap
  bsims <- replicate(nboot, {
    dboot <- rbind(d[-oos,,drop=FALSE], d[R + iboot(P,b),])
    pnull <- apply.oos(R, dboot, null, "recursive", "forecast")
    if (is.function(xfn)) {
      X <- xfn(dboot)
      B <- solve(crossprod(X)/nrow(d))
      sapply(names(palt), function(a) {
        stats <- calmain(dboot, R, pnull, dboot[oos,a], yfn, xfn,
                         crossprod(B, colMeans(X[oos,,drop=FALSE] * (pnull - dboot[oos,a]))))
        (stats[1] - bootmean[a]) / stats[2]
      })
    } else {
      sapply(names(palt), function(a) {
        stats <- calmain(dboot, R, pnull, dboot[oos,a], yfn)
        (stats[1] - bootmean[a]) / stats[2]
    })
  }})
  if (is.matrix(bsims)) {
    bsims <- data.frame(t(bsims))
  } else {
    bsims <- data.frame(bsims)
  }
  names(bsims) <- names(palt)
  bsims
}

## mc <- data.frame(t(replicate(200, {
##   d <- with(r, rdgp(R + P, isPower))
##   calstat(d, r$R, null, alt, xfn, yfn)
## })))
