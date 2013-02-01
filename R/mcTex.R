source("R/mcSetup.R")
cat(file = "tex/mcDef.tex",
    sprintf("\\newcommand{\\%s}{%d}", c("totalsims", "testsize"),
            c(nsims, 100 * testsize)))
