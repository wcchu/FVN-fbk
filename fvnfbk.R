suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(dtplyr))
suppressPackageStartupMessages(library(FNN))
select <- dplyr::select
# Input:
#   dvar = predictor variables of the reference set
#   dcls = a vector of classes corresponding to dvar. has to be in type Factor.
#   dfbk = a vector of feedbacks corresponding to dvar (== T means pos_fbk response)
#   dquery = predictor variables of the query dataset
#   radius = normalized radius of the neighborhood in variable space
#   keyval = 'rate' (default) rate of success for each class
#            'popularity' proportion of success points in each class to total success points
#   conf.lev = the confidence level for calculating the confidence interval of keyval
# Output: a dataframe with qid (query id), class, and for each class, n_evnets, n_success,
#         upper bound, lower bound, average of keyval
fvnfbk <- function(dvar, dcls, dfbk, dquery, radius, keyval = "rate", conf.lev = 0.95,
                   k.fnn = 0) {
  ## quarantee dvar and dquery are data frames and dcls and dfbk are vectors
  dvar <- data.table(dvar)
  dquery <- data.table(dquery)
  if (is.data.frame(dcls)) {dcls <- dcls[, 1]}
  if (is.data.frame(dfbk)) {dfbk <- dfbk[, 1]}
  ## Combine variables, class, and feedback to form "reference dataset" for NN alg
  dref <- data.table(dvar, class = dcls, success = dfbk)
  nvar <- ncol(dvar)
  nref <- nrow(dref) # number of reference points
  lcls <- unique(dcls) # list of classes
  #ncls <- length(lcls) # number of classes
  u <- list()
  href <- list()
  hque <- list()
  for (cls in lcls) {
    dref_cls <- dref[dref$class == cls, ] ## subset of dref in this class
    u[[cls]] <- vector(length = nvar)
    href[[cls]] <- dref_cls
    hque[[cls]] <- dquery
    for (ivar in 1:nvar) {
      u[[cls]][ivar] <- sd(dref_cls[[ivar]])
      href[[cls]][[ivar]] <- dref_cls[[ivar]]/u[[cls]][ivar]
      hque[[cls]][[ivar]] <- dquery[[ivar]]/u[[cls]][ivar]
    }
  }
  # run through queries and recommend size for each query
  dprob <- c()
  for (iq in 1:nrow(dquery)) {
    # collect data points in ball
    dball <- c()
    for (cls in lcls) {
      k0 <- ifelse(k.fnn == 0, nrow(href[[cls]]), min(k.fnn, nrow(href[[cls]])))
      pts <- get.knnx(data = href[[cls]][, c(1:nvar), with = FALSE],
                      query = hque[[cls]][iq],
                      k = k0)
      dball <- rbind(
        dball,
        href[[cls]][pts$nn.index[which(pts$nn.dist <= radius)]][, c("class", "success")]
      )
    }
    # do statistics in ball
    sball <-
      dball %>%
      group_by(class) %>%
      summarise(n_events = n(), n_success = sum(ifelse(success == T, 1, 0))) %>%
      data.frame() %>%
      right_join(data.frame(class = lcls), by = "class") %>%
      mutate(n_events = ifelse(is.na(n_events), 0, n_events),
             n_success = ifelse(is.na(n_success), 0, n_success),
             upp = NA, low = NA, ave = NA)
    for (ic in 1:nrow(sball)) {
      if (sball$n_events[ic] > 0) { ## this class has data points in the query-ball
        if (keyval == 'popularity') {
          t <- binom.test(sball$n_success[ic], sum(sball$n_success), conf.level = conf.lev)
        } else if (keyval == 'rate') {
          t <- binom.test(sball$n_success[ic], sball$n_events[ic], conf.level = conf.lev)
        }
        sball$upp[ic] <- round(t$conf.int[2], 3)
        sball$low[ic] <- round(t$conf.int[1], 3)
        sball$ave[ic] <- round(t$est, 3)
      }
    }
    dprob <- rbind(dprob, merge(data.frame(qid = iq), sball))
  }
  return(dprob)
}
