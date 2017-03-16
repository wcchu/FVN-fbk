suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(dtplyr))
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
NN <- function(dvar, dcls, dfbk, dquery, radius, keyval = "rate", conf.lev = 0.95) {
  ## quarantee dvar and dquery are data frames and dcls and dfbk are vectors
  dvar <- data.frame(dvar)
  dquery <- data.frame(dquery)
  if (is.data.frame(dcls)) {dcls <- dcls[, 1]}
  if (is.data.frame(dfbk)) {dfbk <- dfbk[, 1]}
  ## Combine variables, class, and feedback to form "reference dataset" for NN alg
  dref <- data.frame(dvar, class = dcls, success = dfbk)
  nvar <- ncol(dvar)
  nref <- nrow(dref) # number of reference points
  lcls <- unique(dcls) # list of classes
  ncls <- length(lcls) # number of classes
  u <- c()
  for (icls in 1:ncls) {
    d_cls <- dref %>% filter(class == lcls[icls]) ## subset of dref in this class
    uvar <- c()
    for (ivar in 1:nvar) {
      uvar[ivar] <- sd(d_cls[, ivar]) ## uvar is a list of standard variations of each variable
    }
    u <- rbind(u, data.frame(t(uvar), class = lcls[icls]))
  }
  # run through queries and recommend size for each query
  dprob <- c()
  for (iq in 1:nrow(dquery)) {
    q <- dquery[iq, ]
    ss <- vector(length = nref)
    for (iref in 1:nref) {
      cls0 <- dref$class[iref]
      if (max(abs(q - dref[iref, c(1:nvar)]) / u[u$class == cls0, c(1:nvar)]) > radius) {
        ## If in any dimension the distance from the query q to the ref in dref is
        ## longer than radius, remove this ref
        ss[iref] <- NA
      } else {
        ss[iref] <- 0.0 ## ss records the distances from the query q to each ref in dref
        for (ivar in 1:nvar) {
          ss[iref] <- ss[iref] + ((dref[iref, ivar] - as.numeric(q[ivar])) / u[u$class == cls0, ivar])^2
        }
      }
    }
    # collect data points in ball
    dball <-
      dref %>%
      mutate(dist = sqrt(ss)) %>%
      filter(!is.na(dist)) %>%
      filter(dist <= radius) %>%
      select(class, success)
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
