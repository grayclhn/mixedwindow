library(OOS)
source("R/mcsetup.R")

dfull <- ts(read.csv("data/monthlyData2009.csv")[,-1],
            start = c(1871, 1), frequency = 12)
stock.returns <- (dfull[,"price"] + dfull[,"dividend"]) / lag(dfull[,"price"], -1) - 1

dfull <- lag(cbind(equity.premium              = lag(log1p(stock.returns)
                 - log1p(dfull[,"risk.free.rate"]), 1),
               default.yield.spread        = dfull[,"baa.rate"] - dfull[,"aaa.rate"],
               inflation                   = dfull[,"inflation"],
               stock.variance              = dfull[,"stock.variance"],
               dividend.payout.ratio       = log(dfull[,"dividend"]) - log(dfull[,"earnings"]),
               long.term.yield             = dfull[,"long.term.yield"],
               term.spread                 = dfull[,"long.term.yield"] - dfull[,"t.bill"],
               treasury.bill               = dfull[,"t.bill"],
               default.return.spread       = dfull[,"corp.bond"] - dfull[,"long.term.rate"],
               dividend.price.ratio        = log(dfull[,"dividend"]) - log(dfull[,"price"]),
               dividend.yield              = log(dfull[,"dividend"]) - log(lag(dfull[,"price"], -1)),
               long.term.rate              = dfull[,"long.term.rate"],
               earnings.price.ratio        = log(dfull[,"earnings"]) - log(dfull[,"price"]),
               book.to.market              = dfull[,"book.to.market"],
               net.equity                  = dfull[,"net.equity"]),
         k=-1)
d <- data.frame(window(dfull, start = c(1927,1), end = c(2009,12)))
R <- 120 ## do a ten year window?

## calculate Goyal and Welch's original forecasts
preds <- as.data.frame(lapply(setdiff(names(d), "equity.premium"), function(n) {
  apply.oos(R, d, function(d) lm(formula(paste("equity.premium ~", n)), data = d))}))
names(preds) <- setdiff(names(d), "equity.premium")

## impose Campbell and Thompson's non-negativity requirement
preds.CT <- as.data.frame(lapply(preds, function(x) pmax(x, 0)))

## estimate aggregate forecasts
preds$avg <- apply(as.matrix(preds), 1, mean)
preds$med <- apply(as.matrix(preds), 1, median)

preds.CT$avg <- apply(as.matrix(preds.CT), 1, mean)
preds.CT$med <- apply(as.matrix(preds.CT), 1, median)

## combine the forecasts into a single data frame
names(preds.CT) <- paste(names(preds.CT), "CT", sep = ".")
allpreds <- cbind(preds, preds.CT)

## test for out-performing models
results <- caltest(subset(d, select = equity.premium), R,
                   function(d) lm(equity.premium ~ 1, data = d), allpreds,
                   function(d) matrix(1, nrow(d)),
                   function(d) d[,"equity.premium"],
                   1/150, 600, .05)
