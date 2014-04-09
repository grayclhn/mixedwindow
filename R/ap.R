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

library(oosanalysis, lib.loc = "lib")
library(dbframe, lib.loc = "lib")

## These parameters are going to be reported in the paper as well.
size <- 0.10
windowlength <- 10
ndraw <- 1999

gwdata <- ts(read.csv("data/yearlyData2009.csv")[,-1], start = 1871, frequency = 1)
stock.returns <- ((gwdata[,"price"] + gwdata[,"dividend"]) / 
                                           lag(gwdata[,"price"], -1) - 1)
financial.data <- 
  data.frame(window(start = 1927, end = 2009, lag(k = -1, cbind(
    equity.premium =        lag(log1p(stock.returns) - log1p(gwdata[,"risk.free.rate"]), 1),
    default.yield.spread =  gwdata[,"baa.rate"] - gwdata[,"aaa.rate"],
    inflation =             gwdata[,"inflation"],
    stock.variance =        gwdata[,"stock.variance"],
    dividend.payout.ratio = log(gwdata[,"dividend"]) - log(gwdata[,"earnings"]),
    long.term.yield =       gwdata[,"long.term.yield"],
    term.spread =           gwdata[,"long.term.yield"] - gwdata[,"t.bill"],
    treasury.bill =         gwdata[,"t.bill"],
    default.return.spread = gwdata[,"corp.bond"] - gwdata[,"long.term.rate"],
    dividend.price.ratio =  log(gwdata[,"dividend"]) - log(gwdata[,"price"]),
    dividend.yield =        log(gwdata[,"dividend"]) - log(lag(gwdata[,"price"], -1)),
    long.term.rate =        gwdata[,"long.term.rate"],
    earnings.price.ratio =  log(gwdata[,"earnings"]) - log(gwdata[,"price"]),
    book.to.market =        gwdata[,"book.to.market"],
    net.equity =            gwdata[,"net.equity"]))))

predictor.names <- setdiff(names(financial.data), "equity.premium")
names(predictor.names) <- predictor.names

benchmark <- function(d) lm(equity.premium ~ 1, data = d)
alternatives_gw <- lapply(predictor.names, function(n)
  eval(parse(text = sprintf("function(d) lm(equity.premium ~ %s, data = d)",
			    n))))
alternatives_ct <- lapply(predictor.names, function(n)
  eval(parse(text = sprintf("function(d)
			       CT(lm(equity.premium ~ %s, data = d))", n))))
names(alternatives_ct) <- paste(names(alternatives_ct), "CT", sep = ".")

alternatives_mean <-
  eval(parse(text = sprintf("function(d) Aggregate(%s, mean)",
    sprintf("list(%s)", paste(collapse = ",\n ",
    sapply(sprintf("lm(equity.premium ~ %s, data = d)", predictor.names),
	   function(lmstring) c(lmstring, sprintf("CT(%s)", lmstring))))))))

alternatives_median <-
  eval(parse(text = sprintf("function(d) Aggregate(%s, median)",
    sprintf("list(%s)", paste(collapse = ",\n ",
    sapply(sprintf("lm(equity.premium ~ %s, data = d)", predictor.names),
	   function(lmstring) c(lmstring, sprintf("CT(%s)", lmstring))))))))

alternatives <- c(alternatives_gw, alternatives_ct,
                  average = alternatives_mean, median = alternatives_median)
nmod <- length(alternatives)

oosstats <- mixedwindow(benchmark, alternatives, financial.data,
                        windowlength, window = "rolling", pimethod = "theory")
Sigma <- makecorr(oosstats$avar)
critval <- quantile(replicate(ndraw, max(mvrnorm(1, rep(0, nmod), Sigma))), 1 - size)

results.data <- data.frame(stringsAsFactors = FALSE,
                           predictor = names(oosstats$tstat),
                           value = oosstats$tstat,
                           naive = ifelse(oosstats$tstat > qnorm(1 - size), "sig.", ""),
                           corrected = ifelse(oosstats$tstat > critval, "sig.", ""))

results.data <- results.data[order(results.data$value, decreasing = TRUE),]
results.data$predictor <- gsub(" \\.CT", "(\\\\textsc{ct})", results.data$predictor)
results.data$predictor <- gsub("\\.", " ", results.data$predictor)
names(results.data)[1] <- " "

integer.macros <- c(size = 100 * size, windowlength = windowlength,
                    nmod = nmod, empiricaldraws = ndraw)
real.macros <- c(empiricalcriticalvalue = unname(critval),
                 naivecriticalvalue = qnorm(1-size))

cat(file = "tex/ap.tex", sep = "\n",
    sprintf("\\newcommand{\\%s}{%.2f}", names(real.macros), real.macros),
    sprintf("\\newcommand{\\%s}{%d}", names(integer.macros), integer.macros),
    sprintf("\\newcommand{\\empiricaltable}{%s}",
            booktabs(results.data, align = c("l", rep("C", 3)), 
                     numberformat = c(FALSE, TRUE, FALSE, FALSE),
                     digits = rep(2, 4)),"}"))
