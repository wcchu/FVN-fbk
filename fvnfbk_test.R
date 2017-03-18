suppressMessages(library(dplyr))
suppressMessages(library(dtplyr))
suppressMessages(library(data.table))
suppressMessages(require(MASS))
select <- dplyr::select

set.seed(1)

data <-
  Cars93 %>%
  mutate(Man.trans.avail = ifelse(Man.trans.avail == "Yes", TRUE, FALSE)) %>%
  select(Horsepower, Passengers, DriveTrain, Man.trans.avail) %>%
  data.table()
  
samp <- sample(nrow(data), nrow(data)/3)
que <- data[samp]
ref <- data[!samp]

suppressMessages(source("fvnfbk.R"))
p <- fvnfbk(dvar = ref[, c("Horsepower", "Passengers")],
            dcls = ref[["DriveTrain"]], 
            dfbk = ref[["Man.trans.avail"]],
            dquery = que[, c("Horsepower", "Passengers")],
            radius = 0.5,
            keyval = "rate",
            conf.lev = 0.95,
            k.fnn = 10)