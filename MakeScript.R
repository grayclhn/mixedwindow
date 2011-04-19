# The basic idea of this python script is to set up the right
# dependencies for GNU make so that the monte carlo simulations are
# run in parallel.  Running this file will print out text for a
# makefile, so it might be easiest to just look at its output.

nsims <- 1000  # this is the number of simulations
njobs <- 8     # I set this to equal the number of processors on my 
               # computer.  Changing its value will change the results
               # of the simulations, since they'll be seeded differently.

### split the simulations across the jobs
remainder <- nsims %% njobs
jsims = rep(nsims %/% njobs, njobs) + c(rep(1, remainder), rep(0, njobs - remainder))
### check for dumb errors
stopifnot(sum(jsims) == nsims)

dbdir <- "db"

dbnames <- function(table)
  sapply(seq.int(njobs), function(i) paste(table, i, sep = ""))
dbfiles <- function(filename)
  paste(dbdir, "/", filename, ".db", sep = "")

mkline <- function(...)
    cat(paste("\n\t$(sqlite) $(sqliteflags) stardata.db \"",
              paste(...,sep = ""), ";\"", sep = ""))

mergetables <- function(table) {
  dbn <- dbnames(table)
  dbf <- dbfiles(dbn)
  cat(sprintf("\ndb/%s.done: %s", table, dbf), sep = "")
  mkline(paste(sprintf("attach database '%s' as %s;", dbf, dbn), collapse = " "),
         sprintf("drop table if exists main.%s; ", table),
         sprintf("create table main.%s as %s;",
                 table, paste(sprintf("select * from %s.%s", dbn, table),
                              collapse = " union all ")),
         paste(sprintf("detach database %s;", dbn), collapse = " "))
  cat("\n\ttouch $@")
}

writeMake <- function(x, Rfile, seed) {
  ## This is the set of make commands to create the individual databases.
  dbn <- dbnames(x)
  dbf <- dbfiles(dbn)
  cat("\n.SECONDARY: ", dbf, collapse = "", sep = " ")
  mergetables(x)
  for (job in seq.int(njobs)) {
    cat(sprintf("\n%s: %s\n\tmkdir -p db\n\techo 'seed <- %d; jjob <- %d; nsim <- %d; dbtable <- \"%s\";' | cat - $< | $(Rscript) $(RSCRIPTFLAGS) - &> %s/%s.Rout",
                dbf[job], Rfile, seed, job, jsims[job], x, dbdir, dbn[job]))
  }
}

writeMake("dgp1", "R/montecarlo.R", 99120)
