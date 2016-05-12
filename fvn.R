# Input:
#   dvar = predictor variables of the reference set
#   dcls = a vector of classes corresponding to dvar. has to be in type Factor.
#   dfbk = a vector of feedbacks corresponding to dvar (== T means positive response)
#   dquery = predictor variables of the query dataset
#   radius = normalized radius of the neighborhood in variable space
#   min.frac = minimun fraction of the points in a class to the total number of points
#              in the neighborhood so that this class is a candidate class to be
#              recommended
#   min.cls = minimun number of the points in a class in the neighborhood so that this
#             class is a candidate class to be recommended
#   op = 'rate' recommends the class with the highest rate of positive == T
#        'popularity' recommends the class with the most points of positive == T
# Output: recommended sizes (vector)
NN <- function(dvar, dcls, dfbk, dquery, radius, min.frac, min.cls, op) {
  # * process training data to create "reference data" for NN alg
  dref <- data.frame(dvar, class = dcls, positive = dfbk)
  nvar <- ncol(dvar) # number of variables
  nref <- nrow(dvar) # number of reference points
  lcls <- unique(dcls) # list of classes
  ncls <- length(lcls) # number of classes
  u <- c()
  for (icls in 1:ncls) {
    d_cls <- dref %>% filter(class == lcls[icls])
    uvar <- c()
    for (ivar in 1:nvar) {
      uvar[ivar] <- sd(d_cls[, ivar])
    }
    u <- rbind(u, data.frame(t(uvar), class = lcls[icls]))
  }
  # dcls
  c <- data.frame(class = dcls)
  # a dataset with the same dims as dvar to record units
  dunt <-
    left_join(c, u, by = c("class" = "class")) %>%
    select(-class)
  # run through queries and recommend size for each query
  nq <- nrow(dquery)
  rcls <- factor(levels = levels(dcls))
  rscr <- c()
  #drec <- c()
  for (iq in 1:nq) {
    q <- dquery[iq, ]
    ss <- vector(length = nref)
    for (ivar in 1:nvar) {
      ss <- ss + ((dvar[, ivar] - as.numeric(q[ivar])) / dunt[, ivar])^2
    }
    distance <- sqrt(ss)
    dref$dist <- distance
    # collect data points in ball
    dball <-
      dref %>%
      filter(dist <= radius) %>%
      select(class, positive)
    n_total = nrow(dball)
    # do statistics in ball
    sball <-
      dball %>%
      group_by(class) %>%
      summarise(n_cls = n(), n_pos = sum(ifelse(positive == T, 1, 0))) %>%
      mutate(
        n = n_total,
        frac = n_cls / n_total,
        n_neg = n_cls - n_pos,
        neg_rate = n_neg / n_cls
      ) %>%
      filter(frac >= min.frac, n_cls >= min.cls, n_cls > 1) %>%
      data.frame()
    if (op == 'rate') {
      theclass = arrange(sball, neg_rate)$class[1]
      thescore = arrange(sball, neg_rate)$neg_rate[1]
    }
    if (op == 'popularity') {
      theclass = arrange(sball, desc(n_pos))$class[1]
      thescore = arrange(sball, desc(n_pos))$n_pos[1]
    }
    rcls[iq] <- theclass
    rscr[iq] <- thescore
  }
  return(data.frame(cls = rcls, scr = rscr))
}
