calstat <- function(d, R, null, alt, xfn, yfn) {
  n <- nrow(d)
  oos <- (R+1):n
  P <- n - R
  
  pnull <- apply.oos(R, d, null, "recursive", "forecast")
  enull <- apply.oos(R, d, null, "recursive", "error")
  palt <- apply.oos(R, d, alt, "rolling", "forecast")
  ealt <- apply.oos(R, d, alt, "rolling", "error")
  
  f <- enull^2 - ealt^2 + (pnull - palt)^2
  X <- xfn(d)
  Y <- yfn(d)
  FBh <- drop(tcrossprod(solve(crossprod(X) / n,
                               colMeans(c(2 * pnull - palt - Y[oos]) * X[oos,,drop=FALSE])),
                         c(enull) * X[oos,,drop=FALSE]))
  S <- var(cbind(f, FBh))
  sd <- sqrt((S[1,1] + 2 * S[1,2] + 2 * S[2,2]) / P)
  fbar <- mean(f)
  
  c(pval(fbar, sd, oneSided=TRUE), pval(fbar, sd, oneSided=FALSE))
}

pval <- function(x, sd, oneSided)
  ifelse(oneSided, pnorm(x, 0, sd, lower.tail = FALSE),
         2 * pnorm(abs(x), 0, sd, lower.tail = FALSE))
