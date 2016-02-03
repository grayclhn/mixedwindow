pkgname <- "oosanalysis"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('oosanalysis')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
cleanEx()
nameEx("Classes")
### * Classes

flush(stderr()); flush(stdout())

### Name: Classes
### Title: Some classes to simplify making predictions
### Aliases: Aggregate CT predict.CT predict.Aggregate HasMethod
### Keywords: classes models

### ** Examples

  olddata <- data.frame(y = rnorm(30), x = rnorm(30))
  newdata <- data.frame(y = rnorm(3), x = rnorm(3))

  m1 <- lm(y ~ 1, data = olddata)
  m2 <- lm(y ~ x, data = olddata)

  m3 <- CT(m2)
  m4 <- Aggregate(list(m1, m2, m3), median)

  predict(m3, newdata)
  predict(m4, newdata)

  HasMethod(m1, c("plot", "print", "predict", "median"))



cleanEx()
nameEx("bootindex")
### * bootindex

flush(stderr()); flush(stdout())

### Name: bootindex_circularblock
### Title: Indices to induce block bootstraps
### Aliases: bootindex_circularblock bootindex_movingblock
###   bootindex_stationary
### Keywords: htest distribution ts

### ** Examples

## Example of hypothesis test that mean = 0
nobs <- 200
nboot <- 299
level <- .1
X <- 2 + arima.sim(n = nobs, list(ma = c(0.5)))

naive <- replicate(nboot, mean(X[sample(1:nobs, nobs, replace = TRUE)])) - mean(X)
smart1 <- replicate(nboot, mean(X[bootindex_circularblock(nobs, 5)])) - mean(X)
smart2 <- replicate(nboot, mean(X[bootindex_movingblock(nobs, 5)])) - mean(X)
smart3 <- replicate(nboot, mean(X[bootindex_stationary(nobs, 5)])) - mean(X)

## corresponding critical values
quantile(naive, 1 - level)
quantile(smart1, 1 - level)
quantile(smart2, 1 - level)
quantile(smart3, 1 - level)

## Not run: 
##D mc <- replicate(300, {
##D   X <- arima.sim(n = nobs, list(ma = c(0.5)))
##D   naive <- replicate(nboot, mean(X[sample(1:nobs, nobs, replace = TRUE)])) - mean(X)
##D   smart <- replicate(nboot, mean(X[bootindex_circularblock(nobs, 5)])) - mean(X)
##D   c(naive = mean(X) >= quantile(naive, 1 - level),
##D     smart = mean(X) >= quantile(smart, 1 - level))
##D   })
##D rowMeans(mc)
## End(Not run)



cleanEx()
nameEx("clarkwest")
### * clarkwest

flush(stderr()); flush(stdout())

### Name: clarkwest
### Title: Clark and West's (2006, 2007) Out-of-Sample Test
### Aliases: clarkwest clarkwest_calculation
### Keywords: ts htest models

### ** Examples

x <- rnorm(100)
d <- data.frame(y = x + rnorm(100), x = x)
R <- 70

model1 <- function(d) lm(y ~ 1, data = d)
model2 <- function(d) lm(y ~ x, data = d)

clarkwest(model1, model2, d, R, window = "rolling")



cleanEx()
nameEx("dmw")
### * dmw

flush(stderr()); flush(stdout())

### Name: dmw_mse
### Title: Diebold-Mariano-West out-of-sample t-test
### Aliases: dmw_mse dmw_calculation mixedwindow mixedbootstrap
### Keywords: ts htest models

### ** Examples

x <- rnorm(100)
d <- data.frame(y = x + rnorm(100), x = x)
R <- 70
oos <- 71:100

error.model1 <- d$y[oos] - predict(lm(y ~ 1, data = d[-oos,]),
                                   newdata = d[oos,])
error.model2 <- d$y[oos] - predict(lm(y ~ x, data = d[-oos,]),
                                   newdata = d[oos,])
# test that the two models have equal population MSE.  Note that F = 0
# in this setting.
estimates <-
  dmw_calculation(error.model1^2 - error.model2^2,
                  cbind(error.model1, error.model2, error.model2 * x),
                  R = R, vcv = var)
# calculate p-value for a one-sided test
pnorm(estimates$mu * sqrt(length(oos) / estimates$avar))


n <- 30
R <- 5
d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))
model0 <- function(d) lm(y ~ 1, data = d)
model1 <- function(d) lm(y ~ x1, data = d)
model2 <- function(d) lm(y ~ x2, data = d)
model3 <- function(d) lm(y ~ x1 + x2, data = d)

mixedwindow(model0, model1, d, R, var, window = "rolling")

mixedbootstrap(model0, list(m1 = model1, m2 = model2, m3 = model3),
               d, R, 199, 7, var, "fixed", "circular")



cleanEx()
nameEx("extract")
### * extract

flush(stderr()); flush(stdout())

### Name: extract_target
### Title: Convenience function to extract data from a model
### Aliases: extract_target extract_predictors
### Keywords: models

### ** Examples

model <- function(d) lm(y ~ x, data = d)
dataset <- data.frame(y = rnorm(10), x = rnorm(10))

## Don't show: 
stopifnot(isTRUE(
## End(Don't show)
all.equal(extract_target(model, dataset), dataset$y,
          check.attributes = FALSE)
## Don't show: 
))
## End(Don't show)

## Don't show: 
stopifnot(isTRUE(
## End(Don't show)
all.equal(extract_predictors(model, dataset),
          cbind(1, dataset$x), check.attributes = FALSE)
## Don't show: 
))
## End(Don't show)



cleanEx()
nameEx("mccracken")
### * mccracken

flush(stderr()); flush(stdout())

### Name: mccracken_criticalvalue
### Title: Returns McCracken's (2007) oos-t critical values
### Aliases: mccracken_criticalvalue
### Keywords: ts htest

### ** Examples

mccracken_criticalvalue(.4, 5, .9, "rolling")
mccracken_criticalvalue(.4, 5, .9, "recursive")
mccracken_criticalvalue(.4, 5, .9, "fixed")



cleanEx()
nameEx("recursive-forecasts")
### * recursive-forecasts

flush(stderr()); flush(stdout())

### Name: recursive_forecasts
### Title: Pseudo out-of-sample forecasts
### Aliases: recursive_forecasts
### Keywords: ts models

### ** Examples

d <- data.frame(x = rnorm(15), y = rnorm(15))
ols <- function(d) lm(y ~ x, data = d)
## Basic Usage:
recursive_forecasts(ols, d, 4, "recursive")

## Illustrate different estimation windows by comparing forecasts for
## observation 11 (note that the forecast for observation 11 will be the
## 7th element that apply.oos returns in this example)
newd <- d[11,]

## Don't show: 
stopifnot(
## End(Don't show)
all.equal(predict(lm(y ~ x, data = d[7:10,]), d[11,]),
          recursive_forecasts(ols, d, 4, "rolling")[7])
## Don't show: 
)
## End(Don't show)

## Don't show: 
stopifnot(
## End(Don't show)
all.equal(predict(lm(y ~ x, data = d[1:10,]), d[11,]),
          recursive_forecasts(ols, d, 4, "recursive")[7])
## Don't show: 
)
## End(Don't show)

## Don't show: 
stopifnot(
## End(Don't show)
all.equal(predict(lm(y ~ x, data = d[1:4,]), d[11,]),
          recursive_forecasts(ols, d, 4, "fixed")[7])
## Don't show: 
)
## End(Don't show)



cleanEx()
nameEx("rvar")
### * rvar

flush(stderr()); flush(stdout())

### Name: rvar
### Title: Generate pseudo-random data from a Vector Autoregression
### Aliases: rvar
### Keywords: datagen ts

### ** Examples

d <- rvar(10000, list(a = c(0.5, 0, 0.2, 0.1),
                      b = c(0.1, 0.2, 0.5, 0)),
          c(4, 6), diag(2))

lm(a ~ aL1 + aL2 + bL1 + bL2, data = d)
lm(b ~ aL1 + aL2 + bL1 + bL2, data = d)



cleanEx()
nameEx("stepm")
### * stepm

flush(stderr()); flush(stdout())

### Name: stepm
### Title: Romano and Wolf's (2005) StepM
### Aliases: stepm
### Keywords: htest

### ** Examples

n <- 50
nboot <- 99
d <- data.frame(x1 = rnorm(n), x2 = rnorm(n) + 1, x3 = rnorm(n))

dottests <- function(dataset)
  sapply(dataset, function(x) t.test(x)$statistic)

stepm(teststatistics = dottests(d),
      bootmatrix = replicate(nboot, dottests(d[sample(1:n, n, replace = TRUE),])),
      lefttail = NA, righttail = 0.05)



### * <FOOTER>
###
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')
