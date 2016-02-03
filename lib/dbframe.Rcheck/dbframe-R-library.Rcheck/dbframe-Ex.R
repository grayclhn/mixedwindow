pkgname <- "dbframe"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
library('dbframe')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
cleanEx()
nameEx("booktabs")
### * booktabs

flush(stderr()); flush(stdout())

### Name: booktabs
### Title: Construct a nice table from a data frame
### Aliases: booktabs
### Keywords: methods printing

### ** Examples

data(chickwts)
cat(booktabs(head(chickwts)))



cleanEx()
nameEx("clear")
### * clear

flush(stderr()); flush(stdout())

### Name: clear
### Title: Remove a table from the database
### Aliases: clear clear-methods clear,dbframe-method
### Keywords: database methods

### ** Examples

filename <- tempfile(fileext = ".db")
example.dbframe <- dbframe("clear1", dbname = filename)
example2.dbframe <- dbframe("clear2", dbname = filename)
clear(example.dbframe, example2.dbframe)

data(chickwts)
insert(example.dbframe) <- chickwts
head(example.dbframe)
clear(example.dbframe)
head(example.dbframe)
unlink(filename)



cleanEx()
nameEx("dbframe-package")
### * dbframe-package

flush(stderr()); flush(stdout())

### Name: dbframe-package
### Title: An overview of the dbframe package
### Aliases: dbframe-package
### Keywords: package database

### ** Examples

filename <- tempfile(fileext = ".db")
example.dbframe <- dbframe("package1", dbname = filename, clear = TRUE)
data(chickwts)
insert(example.dbframe) <- chickwts
select(example.dbframe, "avg(weight)", group.by = "feed")
unlink(filename)



cleanEx()
nameEx("dbframe")
### * dbframe

flush(stderr()); flush(stdout())

### Name: dbframe
### Title: Create a 'dbframe' object
### Aliases: dbframe dbframe_sqlite dbframe_sqlite_temporary
###   dbframe_unknown
### Keywords: database interface

### ** Examples

data(chickwts)
filename <- tempfile(fileext = ".db")
example <- dbframe("dbframe1", dbname = "filename", dbdriver = "SQLite",
                   data = chickwts)
tail(example)
## an example where "table" is a select statement on its own

## clean up
unlink(filename)



cleanEx()
nameEx("head")
### * head

flush(stderr()); flush(stdout())

### Name: head
### Title: Retrieve head or tail of a table
### Aliases: nrec head.dbframe tail.dbframe
### Keywords: database

### ** Examples

data(chickwts)
filename <- tempfile(fileext = ".db")
chicksdb <- dbframe("head1", dbdriver = "SQLite", dbname = filename,
                    data = chickwts)
head(chickwts)
tail(chickwts, -60)
tail(chickwts)
unlink(filename)



cleanEx()
nameEx("insert")
### * insert

flush(stderr()); flush(stdout())

### Name: insert<-
### Title: Insert a data frame into the sql database
### Aliases: insert<- insert<--methods insert<-,dbframe-method
### Keywords: database

### ** Examples

data(chickwts)
filename <- tempfile(fileext = ".db")
chicksdb <- dbframe("insert1", dbdriver = "SQLite", 
                    dbname = filename, clear = TRUE)
## Add some records
insert(chicksdb) <- chickwts[1:2,]
select(chicksdb)
## Add some more
insert(chicksdb) <- tail(chickwts)



cleanEx()
nameEx("rows")
### * rows

flush(stderr()); flush(stdout())

### Name: rows
### Title: Extract rows from a data frame and present as a list
### Aliases: rows
### Keywords: utilities

### ** Examples

data(chickwts)
for (r in rows(head(chickwts))) print(r)



cleanEx()
nameEx("select")
### * select

flush(stderr()); flush(stdout())

### Name: select
### Title: Retrieve records from a dbframe
### Aliases: select select-methods select,ANY,missing-method
###   select,data.frame,character-method select,dbframe,character-method
###   select,dbframe,list-method select,default,missing-method
###   select,list,character-method generate.select.sql
### Keywords: methods database

### ** Examples

filename <- tempfile(fileext = ".db")
data(chickwts)
chicksdb <- dbframe("select1", dbname = filename, 
                    clear = TRUE, data = chickwts)
select(chicksdb, where = "weight > 200", order.by = "weight")
select(chicksdb, c(averageweight = "avg(weight)"), group.by = "feed")
select(chicksdb, c(averageweight = "avg(weight)"), group.by = "feed",
       having = "averageweight > 250")

## and an example of querying the data frame directly
select(chickwts, c(averageweight = "avg(weight)"), 
       group.by = c(thefeed = "feed"))
avgwts <- dbframe("select2", dbname = filename, clear = TRUE,
                  data = select(chickwts, c(averageweight = "avg(weight)"), 
                                group.by = c(thefeed = "feed")))
## an example of a join
select(list(a = chicksdb, b = avgwts), c("feed", "weight", "averageweight"),
       on = ("feed = thefeed"), order.by = "feed, weight")



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
