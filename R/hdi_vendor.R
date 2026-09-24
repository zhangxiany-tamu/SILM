# This file is copied verbatim from the 'hdi' package, version 0.1-10
# (archived CRAN tarball hdi_0.1-10.tar.gz, sha256
# 15f37a620e2c51b158d50472e442b34391c7eef92acd9291e8d468e14ba49206):
# R/lasso-proj.R and R/boot.lasso-proj.R in full, and the functions of
# R/helpers.R and R/methods.R that they use. hdi is Copyright (C) Lukas Meier,
# Ruben Dezeure, Nicolai Meinshausen, Martin Maechler and Peter Buehlmann,
# licensed under the GPL; it is redistributed here under GPL-3. See
# inst/COPYRIGHTS. This is the baseline for the port in the next commit; the
# only change is an hdi_ prefix on the four entry points (not exported).
#
# ---- R/lasso-proj.R ---------------------------------------------------------
hdi_lasso.proj <- function(x, y, family = "gaussian",
                       standardize = TRUE,
                       multiplecorr.method = "holm",
                       N = 10000,
                       parallel = FALSE, ncores = getOption("mc.cores", 2L),
                       betainit = "cv lasso",
                       sigma = NULL, ## sigma estimate provided by the user
                       Z = NULL,     ## Z or Thetahat provided by the user
                       verbose = FALSE,
                       return.Z = FALSE,
                       suppress.grouptesting = FALSE,
                       robust = FALSE,
                       do.ZnZ = FALSE)
{
  ## Purpose:
  ## An implementation of the LDPE method http://arxiv.org/abs/1110.2563
  ## which is identical to
  ## http://arxiv.org/abs/1303.0518
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## ----------------------------------------------------------------------
  ## Return values:
  ## pval: p-values for every parameter (individual tests)
  ## pval.corr:  multiple testing corrected p-values for every parameter
  ## betahat:    initial estimate by the scaled lasso of \beta^0
  ## bhat:       de-sparsified \beta^0 estimate used for p-value calculation
  ## sigmahat:   \sigma estimate coming from the lasso
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 18 Oct 2013 (initial version),
  ## in part based on an implementation of the ridge projection method
  ## ridge-proj.R by P. Buehlmann + adaptations by L. Meier.

  ####################
  ## Get data ready ##
  ####################
  n <- nrow(x)
  p <- ncol(x)

  if(standardize)
    sds <- apply(x, 2, sd)
  else
    sds <- rep(1, p)

  pdata <- prepare.data(x = x,
                        y = y,
                        standardize = standardize,
                        family = family)
  x <- pdata$x
  y <- pdata$y
  
  ## force sigmahat to 1 when doing glm!
  if(family == "binomial")
    sigma <- 1

  ######################################
  ## Calculate Z using nodewise lasso ##
  ######################################
  
  Zout <- calculate.Z(x = x,
                      parallel = parallel,
                      ncores = ncores,
                      verbose = verbose,
                      Z = Z,
                      do.ZnZ = do.ZnZ)
  Z <- Zout$Z
  scaleZ <- Zout$scaleZ
  
  ###################################
  ## de-sparsified Lasso estimator ##
  ###################################
  
  ## Initial Lasso estimate
  initial.estimate <- initial.estimator(betainit = betainit, sigma = sigma,
                                        x = x, y = y)
  betalasso <- initial.estimate$beta.lasso
  sigmahat <- initial.estimate$sigmahat

  ## de-sparsified Lasso
  bproj <- despars.lasso.est(x = x,
                             y = y,
                             Z = Z,
                             betalasso = betalasso)
  
  #########################
  ## p-Value calculation ##
  #########################

  se <- est.stderr.despars.lasso(x = x,
                                 y = y,
                                 Z = Z,
                                 betalasso = betalasso,
                                 sigmahat = sigmahat,
                                 robust = robust)
  scaleb <- 1/se
  
  bprojrescaled <- bproj * scaleb
  
  ## Calculate p-value
  pval <- 2 * pnorm(abs(bprojrescaled), lower.tail = FALSE)

  cov2 <- crossprod(Z)

  #################################
  ## Multiple testing correction ##
  #################################

  pcorr <- if(multiplecorr.method == "WY") {
             ## Westfall-Young like procedure as in ridge projection method,
             ## P.Buhlmann & L.Meier
             ## method related to the Westfall - Young procedure
             ## constants left out since we'll rescale anyway
             ## otherwise cov2 <- crossprod(Z)/n
             p.adjust.wy(cov = cov2, pval = pval, N = N)
           } else if(multiplecorr.method %in% p.adjust.methods) {
             p.adjust(pval,method = multiplecorr.method)
           } else
             stop("Unknown multiple correction method specified")


  ##############################################
  ## Function to calculate p-value for groups ##
  ##############################################
  if(suppress.grouptesting){
    group.testing.function <- NULL
    cluster.group.testing.function <- NULL
  }else{
    pre <- preprocess.group.testing(N = N, cov = cov2, conservative = FALSE)
    
    group.testing.function <- function(group, conservative = TRUE){
      calculate.pvalue.for.group(brescaled    = bprojrescaled,
                                 group        = group,
                                 individual   = pval,
                                 ##correct    = TRUE,
                                 conservative = conservative,
                                 zz2          = pre)
    }
    
    cluster.group.testing.function <-
      get.clusterGroupTest.function(group.testing.function =
                                      group.testing.function, x = x)
  }
  
  ############################
  ## Return all information ##
  ############################

  out <- list(pval        = as.vector(pval),
              pval.corr   = pcorr,
              groupTest   = group.testing.function,
              clusterGroupTest = cluster.group.testing.function,
              sigmahat    = sigmahat,
              standardize = standardize,
              sds         = sds,
              bhat        = bproj / sds,
              se          = se / sds,
              betahat     = betalasso / sds,
              family      = family,
              method      = "lasso.proj",
              call        = match.call())
  if(return.Z)
    out <- c(out,
             list(Z = scale(Z,center=FALSE,scale=1/scaleZ)))##unrescale the Zs

  names(out$pval) <- names(out$pval.corr) <- names(out$bhat) <-
    names(out$sds) <- names(out$se) <- names(out$betahat) <-
      colnames(x)

  class(out) <- "hdi"
  return(out)
}


# ---- R/boot.lasso-proj.R ----------------------------------------------------
hdi_boot.lasso.proj <- function(x, y, family = "gaussian",
                            standardize = TRUE,
                            multiplecorr.method = "WY",
                            parallel = FALSE, ncores = getOption("mc.cores", 2L),
                            betainit = "cv lasso",
                            sigma = NULL, ## sigma estimate provided by the user
                            Z = NULL,     ## Z or Thetahat provided by the user
                            verbose = FALSE,
                            return.Z = FALSE,## suppress.grouptesting = FALSE,
                            robust = FALSE,
                            B = 1000,
                            boot.shortcut = FALSE,
                            return.bootdist = FALSE,
                            wild = FALSE,
                            gaussian.stub = FALSE)
{
  ## Purpose:
  ## An implementation of the LDPE method http://arxiv.org/abs/1110.2563
  ## (which is identical to http://arxiv.org/abs/1303.0518)
  ## performing inference using the bootstrap techniques from
  ## http://arxiv.org/abs/1606.03940
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## ----------------------------------------------------------------------
  ## Return values:
  ## pval: p-values for every parameter (individual tests)
  ## pval.corr:  multiple testing corrected p-values for every parameter
  ## betahat:    initial estimate by the scaled lasso of \beta^0
  ## bhat:       de-sparsified \beta^0 estimate used for p-value calculation
  ## sigmahat:   \sigma estimate coming from the lasso
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 15 June 2016 (initial version)
  ## in part based on the implementation of the de-sparsified Lasso
  ## lasso-proj.R

  if(!identical(family,"gaussian"))
    stop("The function boot.lasso.proj is currently not supporting families other than 'gaussian'")
  ## The current code assumes the family is gaussian
  ## residual based resampling would be incorrect for other family

  if(!parallel)
    ncores <- 1
  
  ####################
  ## Get data ready ##
  ####################
  n <- nrow(x)
  p <- ncol(x)

  if(standardize)
    sds <- apply(x, 2, sd)
  else
    sds <- rep(1, p)

  pdata <- prepare.data(x = x,
                        y = y,
                        standardize = standardize,
                        family = family)
  x <- pdata$x
  y <- pdata$y
  
  ## force sigmahat to 1 when doing glm!
  if(family == "binomial")
    sigma <- 1
  
  ######################################
  ## Calculate Z using nodewise lasso ##
  ######################################
  
  Zout <- calculate.Z(x = x,
                      parallel = parallel,
                      ncores = ncores,
                      verbose = verbose,
                      Z = Z)
  Z <- Zout$Z
  scaleZ <- Zout$scaleZ
  
  ###################################
  ## de-sparsified Lasso estimator ##
  ###################################
  
  ## Initial Lasso estimate
  initial.estimate <- initial.estimator(betainit = betainit, sigma = sigma,
                                        x = x, y = y)
  betalasso <- initial.estimate$beta.lasso
  sigmahat <- initial.estimate$sigmahat

  ## Lasso residuals
  r <- y - x %*% betalasso
  rc <- as.vector(r) - mean(r)

  ## de-sparsified Lasso
  bproj <- despars.lasso.est(x = x,
                             y = y,
                             Z = Z,
                             betalasso = betalasso)
  se <- est.stderr.despars.lasso(x = x,
                                 y = y,
                                 Z = Z,
                                 betalasso = betalasso,
                                 sigmahat = sigmahat,
                                 robust = robust)
  scaleb <- 1/se
  
  bprojrescaled <- bproj * scaleb


  ############################
  ## Bootstrapping approach ##
  ############################
  
  ## Choose the tuning parameter to be used (or leave open) for the bootstrap
  
  lambda <- NULL
  if(boot.shortcut)
    lambda <- initial.estimate$lambda

  ## ?ISSUE?:
  ## If the user provided his own betainit, we have no lambda value
  ## to use for the bootstrap shortcut, what do we do here?
  ## Let the user provide a lambda as option to the main function in addition to the betainit?
  ## We only allow for lasso for bootstrapping no? so it has to be lambda for lasso :/

  compute.cbootdist <- function(ystar,
                                boot.truth)
  {
    ## Precalculate the initial estimator    
    initstar <- boot.initial.fit(x = x,
                                 ystar = ystar,
                                 betainit = betainit,
                                 lambda = lambda,
                                 parallel = parallel,
                                 ncores = ncores)
    betainitstar <- do.call(cbind,
                            lapply(initstar,
                                   FUN = function(out) out$betalasso))
    sigmahatstar <- sapply(initstar,
                           FUN = function(out) out$sigmahat)
    
    ## Compute the de-sparsified Lasso
    bstar <- despars.lasso.est(x = x,
                               y = ystar,
                               Z = Z,
                               betalasso = betainitstar)
    
    ## Compute the standard errors
    sestar <- boot.se(x = x,
                      ystar = ystar,
                      Z = Z,
                      betainitstar = betainitstar,
                      sigmahatstar = sigmahatstar,
                      robust = robust,
                      parallel = parallel,
                      ncores = ncores)
    ## Compute the final bootstrap distribution
    cboot.dist <- (bstar - boot.truth)/sestar ## Substract the bootstrap truth and studentize
  }
  
  #########################
  ## p-Value calculation ##
  #########################
  
  ## Compute the distribution of the estimator for testing
  
  if(gaussian.stub)
  {
    ## stub Centered bootstrap distribution
    cboot.dist <- replicate(B, rnorm(ncol(x)))
  }else{
    ## Resample the residuals
    rstar <- resample(r = rc,
                      B = B,
                      wild = wild)
    ystar <- as.vector(x %*% betalasso) + rstar
    
    ## Compute the centered bootstrap distribution
    cboot.dist <- compute.cbootdist(ystar = ystar,
                                    boot.truth = betalasso)
  }
  
  ## Compute p-values based on that distribution
  dist <- bproj/se - cboot.dist
  counts <- apply(dist >=0,1,sum)
  if(any(counts >= B/2))
    counts[counts >= B/2] <- B-counts[counts >= B/2]
  counts <- 2*counts
  
  pval <- (counts+1)/(B+1)

  #################################
  ## Multiple testing correction ##
  #################################
  
  cboot.dist.underH0c <- NULL
  pcorr <- if(multiplecorr.method == "WY") {
             ###########################################################################
             ## Bootstrap under H0 complete another B bootstrap samples to perform WY ##
             ###########################################################################
             
             ## Compute the maxT distribution under H0c
             if(gaussian.stub)
             {
               ## stub Centered bootstrap distributionc
               cboot.dist.underH0c <- replicate(B,rnorm(ncol(x)))
             }else{
               ## Use the re-sampled residuals to bootstrap under the complete
               ## null hypothesis.
               
               ystar <- 0 + rstar
               
               ## Compute the centered bootstrap distribution
               cboot.dist.underH0c <- compute.cbootdist(ystar = ystar,
                                                        boot.truth = 0)
             }
             
             max.t.dist <- apply(abs(cboot.dist.underH0c),2,max)
             
             counts.matrix <- sapply(max.t.dist,FUN=">=",abs(bproj/se))
             counts <- apply(counts.matrix,1,sum)
             
             (counts+1)/(B+1)  
           } else if(multiplecorr.method %in% p.adjust.methods) {
             ####################################################################
             ## Check and warn for accuracy of p-values when using traditional ##
             ## multiple testing correction methods                            ##
             ####################################################################

             ## P-values that are so far in the tail that the number of bootstrap
             ## samples didn't suffice to capture
             inaccurate.pval <- pval <= (4+1)/(B+1)
             
             ## Is the lower bound on p-values too small for multiple testing correction?
             B.toosmall.formc <- (1+4)/(B+1)*ncol(x) > 0.05
             ## we don't know what rejection level the user wants to use, but 0.05 is a good reference?
             
             if(any(inaccurate.pval) & B.toosmall.formc)
             {
               warning(paste("Lacking accuracy for multiple testing:\n",
                             "The provided number of bootstrap samples B was not high enough to ",
                             "accurately compute\nthe smallest multiple testing corrected p-values.\n",
                             "The lowest attainable p-value for the chosen B value is 1/(B+1)=",
                             signif(1/(B+1),3),".\n",
                             "Reasonable accuracy is only attained starting from (4+1)/(B+1)=",
                             signif((4+1)/(B+1),3),".\n",
                             "This issue is easily solved by using 'WY' as multiple testing method.",
                             sep=""))
             }
             
             p.adjust(pval,method = multiplecorr.method)
           } else
             stop("Unknown multiple correction method specified")


  ##############################################
  ## Function to calculate p-value for groups ##
  ##############################################

  ## For the moment we don't yet support group testing
  group.testing.function <- NULL
  cluster.group.testing.function <- NULL

  ############################
  ## Return all information ##
  ############################
  
  out <- list(pval        = as.vector(pval),
              pval.corr   = pcorr,
              ##              groupTest   = group.testing.function,
              ##              clusterGroupTest = cluster.group.testing.function,
              sigmahat    = sigmahat,
              standardize = standardize,
              sds         = sds,
              bhat        = bproj / sds,
              se          = se / sds,
              betahat     = betalasso / sds,
              family      = family,
              method      = "boot.lasso.proj",
              B           = B,
              boot.shortcut = boot.shortcut,
              lambda      = lambda,
              call        = match.call())
  if(return.Z)
    out <- c(out,
             list(Z = scale(Z,center=FALSE,scale=1/scaleZ)))##unrescale the Zs
  names(out$pval) <- names(out$pval.corr) <- names(out$bhat) <-
    names(out$sds) <- names(out$se) <- names(out$betahat) <-
    colnames(x)
  if(return.bootdist)
  {
    out <- c(out,
             list(cboot.dist = se/sds*cboot.dist))
    rownames(out$cboot.dist) <- names(out$bhat)
    if(!is.null(cboot.dist.underH0c))
    {
      out <- c(out,
               list(cboot.dist.underH0c = se/sds*cboot.dist.underH0c))      
      rownames(out$cboot.dist.underH0c) <- names(out$bhat)
    }
  }
  class(out) <- "hdi"
  return(out)
}


# ---- R/helpers.R (lines 124-800) --------------------------------------------
calc.ci <- function(bj, se, level = 0.95)
{
  ## Purpose:
  ## calculating confidence intervals with the given coefficients, standard
  ## errors and significance level.
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 6 Feb 2014, 14:27

  quant <- qnorm(1 - (1 - level) / 2)
  list(lci = bj - se * quant,
       rci = bj + se * quant)
}


p.adjust.wy <- function(cov, pval, N = 10000)
{
  ## Purpose:
  ## multiple testing correction with a Westfall young-like procedure as
  ## in ridge projection method, http://arxiv.org/abs/1202.1377 P.Buehlmann
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## cov: covariance matrix of your estimator
  ## pval: the single testing pvalues
  ## N: the number of samples to take for the empirical distribution
  ##    which is used to correct the pvalues
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 6 Feb 2014, 14:27

  ## Simulate distribution
  zz  <- mvrnorm(N, rep(0, ncol(cov)), cov)
  zz2 <- scale(zz, center = FALSE, scale = sqrt(diag(cov)))
  Gz  <- apply(2 * pnorm(abs(zz2),lower.tail = FALSE), 1, min)
  
  ## Corrected p-values  pcorr
  ecdf(Gz)(pval)
}

preprocess.group.testing <- function(N, cov, conservative)
{
  if(conservative){
    ## No preprocessing to perform
    NULL
  } else {
    ## Simulate distribution
    zz  <- mvrnorm(N, rep(0, ncol(cov)), cov)
    scale(zz, center = FALSE, scale = sqrt(diag(cov)))
  }
}

calculate.pvalue.for.group <- function(brescaled, group, individual,
                                       Delta = NULL, conservative = TRUE, zz2)
{
  ## Purpose:
  ## calculation of p-values for groups
  ## using the maximum as test statistic
  ## http://arxiv.org/abs/1202.1377 P.Buehlmann
  ## Author: Ruben Dezeure 2 May 2014
  if(is.list(group)){
    pvalue <- lapply(group,
                     calculate.pvalue.for.group,
                     brescaled = brescaled,
                     individual = individual,
                     Delta = Delta,
                     conservative = conservative,
                     zz2 = zz2)
    pvalue <- unlist(pvalue)
  }else{
    p <- length(brescaled)

    if(!is.logical(group)){
      stopifnot(all(group <= p) & all(group >= 1))
      tmp <- logical(length(brescaled))
      tmp[group] <- TRUE
      group <- tmp
    }

    stopifnot(is.logical(group))
    stopifnot(length(group) == length(brescaled))

    if(conservative){ ## (very) conservative alternative proposed by Nicolai
      pvalue <- min(individual[group])
      ## if(correct){ ## only for alternative method
      pvalue <- min(1, p * pvalue) ## Bonferroni correction
      ##}
    }else{
      ## Max test statistics according to http://arxiv.org/abs/1202.1377
      ## P.Buehlmann
      if(is.null(zz2))
        stop("you need to preprocess zz2 by calling preprocess.group.testing")
      if(sum(group) > 1){
        group.coefficients <- abs(brescaled[group])
        max.coefficient    <- max(group.coefficients)
        group.zz           <- abs(zz2[,group])

        if(!is.null(Delta)){ ## special case Ridge method
          group.Delta <- Delta[group]
          group.zz    <- sweep(group.zz, 2, group.Delta, "+")
        }

        Gz <- apply(group.zz, 1, max)

        ## Determine simulated p-value
        pvalue <- 1 - ecdf(Gz)(max.coefficient)
      }else{ ## if group consists of a single variable
        pvalue <- individual[group]
      }
    }
  }
  return(pvalue)
}

calculate.pvalue.for.cluster <- function(hh, p, pvalfunction,
                                         clusterextractfunction,
                                         alpha, verbose = FALSE) {
  ## Remark: not the cleanest code yet
  ## Purpose:
  ## calculation of p-values hierarchically for a cluster as input
  ## Author: Ruben Dezeure 10 April 2014

  ## test the clusters
  upper.signif     <- rep(TRUE, p) ## the significant clusters one level up
  upper.clust      <- list()       ## the upper significant cluster
  upper.clust[[1]] <- 1:p
  upper.clust.ind  <- list()

  ord <- hh$order## ordering from the cluster

  clusters   <- list()
  pvalue     <- list()
  leftChild  <- list()
  rightChild <- list()
  iter       <- 1
  old.cluster.lengths <- 0
  start <- TRUE
  for(nclust in 1:p){ ## test the subclusters of the significant current clusters
    if(verbose)
      cat("cutting tree into", nclust, "groups\n")

    cut.level <- clusterextractfunction(nclust)## TODO clusterextractfunction
    ## cutree(hh,k=nclust)

    all.signif <- all(upper.signif)
    if(!all.signif){
      cut.level[!upper.signif] <- 0
      ## ignore clusters that are not significant above
    }
    clusters.this.level <- sapply(setdiff(unique(cut.level), 0),
                                  FUN = "==", cut.level)
    cluster.lengths     <- sort(apply(clusters.this.level, 2, sum))

    if(!(identical(cluster.lengths,old.cluster.lengths))){
      ## we went down the tree one level for those clusters we are interested in
      old.cluster.lengths <- cluster.lengths
      if(verbose)
        cat("total number of clusters at this level =",
            ncol(clusters.this.level), "\n")

      stopifnot(ncol(clusters.this.level) > 0)

      current.clusts <- list()
      for(j in 1:ncol(clusters.this.level)){
        current.clusts[[j]] <- which(clusters.this.level[,j])
      }
      ## one of the upper clusters has children
      ## find out which are the children
      are.children <- rep(FALSE,ncol(clusters.this.level))
      has.children <- rep(FALSE,length(upper.clust))
      for(j in 1:length(current.clusts)){## check if current cluster is a child
        for(i in 1:length(upper.clust)){ ## check if it has a child
          if(all(is.element(current.clusts[[j]],upper.clust[[i]])) &&
             (start || !(length(current.clusts[[j]]) ==
                         length(upper.clust[[i]]))))
            { ## current cluster is a child of above
              if(verbose){
                cat("the subcluster of length\n")
                cat(length(current.clusts[[j]]), "\n")
                cat("fits in the cluster of length\n")
                cat(length(upper.clust[[i]]), "\n")
                cat("saving the child for testing\n")
              }
              are.children[j] <- TRUE
              has.children[i] <- TRUE
            }
        }
      }
      if(verbose)
        cat("there are", sum(are.children), "children that we will test.\n")

      if(sum(are.children) > 0){ ## else: we have not encountered children in
                               ##       this level of tree

        ## if there are children it is only possible that there are two
        ## children clusters of
        ## one upper cluster that has children, this is due to the iteration
        ## over cutree
        ## TODO
        if(!start){
          ## add leftchild and rightchild
          ## we assume always that nchildren =2 at this point!
          if(mean(((1:length(ord)))
                  [ord %in%current.clusts[[which(are.children)[2]]]] / p) <
             mean(((1:length(ord)))
                  [ord %in%current.clusts[[which(are.children)[1]]]] / p)){
            left  <- iter + 1
            right <- iter
          }else{
            left  <- iter
            right <- iter + 1
          }
          parent.ind <- upper.clust.ind[[which(has.children)]]
          ## Need to know the index of this in clusters!
          leftChild[[parent.ind]]  <- left
          rightChild[[parent.ind]] <- right
        }
        ## test them
        clusters.to.test <- clusters.this.level[, are.children, drop = FALSE]
        pvals <- pvalfunction(clusters.to.test = clusters.to.test,
                              nclust = nclust)## TODO pvalfunction
        ## mapply(group.testing.function,
        ## group=split(clusters.to.test,col(clusters.to.test)))

        ## save the children and result if it was significant or not
        for(i in 1:sum(are.children)){
          clusters[[iter]]   <- current.clusts[[which(are.children)[i]]]
          leftChild[[iter]]  <- -1  ## initialise on a leaf
          rightChild[[iter]] <- -1 ## initialise on a leaf
          pvalue[[iter]]     <- pvals[i]
          iter <- iter + 1
        }
        ## update the list of clusters that are significant to
        ## keep branching out,
        upper.clust <- upper.clust[!has.children]
        upper.clust.ind <- upper.clust.ind[!has.children]
        tmp.iter <- length(upper.clust)+1
        for(i in which(pvals <= alpha)){
          upper.clust[[tmp.iter]] <- which(clusters.to.test[,i])
          upper.clust.ind[[tmp.iter]] <- iter - sum(are.children) + (i-1)
          ## index in clusters[[]]
          tmp.iter <- tmp.iter + 1
        }
        upper.signif <- 1:p %in% unique(unlist(upper.clust))
        ## done
        if(length(upper.clust) == 0){
          ## there are no more upper significant clusters
          if(verbose){
            cat("reached an end to the cluster tree\n")
            cat("the lowest clusters have sizes:\n")
            cat(apply(clusters.to.test,2,sum), "\n")
          }
          break
        }
      }
    }
    if(start)
      start <- FALSE
  }
  ## return output in the style of lowerbound method
  list(
    clusters   = clusters,
    pval       = unlist(pvalue),
    leftChild  = unlist(leftChild),
    rightChild = unlist(rightChild),
    alpha      = alpha,
    hh         = hh)
}

get.clusterGroupTest.function <- function(group.testing.function, x)
{
  ## Purpose:
  ## facilitate the creation of clusterGrouptest based on the
  ## group.testing.function
  ## Author: Ruben Dezeure 5th of August 2014
  stopifnot(is.function(group.testing.function))

  ## Return  'clusterGroupTest' function :
  function(hcloutput,
           dist = as.dist(1 - abs(cor(x))),
           alpha = 0.05,
           method = "average",
           conservative = TRUE) {
    ## optional argument: hcloutput = the result from a hclust call
    hh <- if(missing(hcloutput))
            hclust(dist, method = method)
          else
            hcloutput

    clusterextractfunction <- function(nclust){
      ## function to extract the correct level of the tree where the number
      ## of clusters = nclust
      cutree(hh, k = nclust)
    }

    pvalfunction <- function(clusters.to.test, nclust){
      ## function to calculate the p-value for certain clusters
      mapply(group.testing.function,
             conservative = conservative,
             group = split(clusters.to.test, col(clusters.to.test)))
    }
    structure(c(calculate.pvalue.for.cluster(hh = hh,
                                           p = ncol(x),
                                           pvalfunction = pvalfunction,
                                           alpha = alpha,
                                           clusterextractfunction =
                                             clusterextractfunction),
                method = "clusterGroupTest"),
              class = c("clusterGroupTest", "hdi"))
  }
}

switch.family <- function(x, y, family)
{
  switch(family,
         "binomial" = {
           fitnet        <- cv.glmnet(x, y, family = "binomial",
                                      standardize = FALSE)
           glmnetfit     <- fitnet$glmnet.fit
           netlambda.min <- fitnet$lambda.min
           netpred <- predict(glmnetfit, x, s = netlambda.min,
                              type = "response")
           betahat <- predict(glmnetfit, x, s = netlambda.min,
                              type = "coefficients")
           betahat <- as.vector(betahat)
           pihat   <- netpred[,1]

           diagW <- pihat * (1 - pihat)
           W     <- diag(diagW)
           xl    <- cbind(rep(1, nrow(x)), x)

           ## Adjusted design matrix
           xw <- sqrt(diagW) * x

           ## Adjusted response
           yw <- sqrt(diagW) * (xl %*% betahat + solve(W, y - pihat))
         },
         {
           stop("The provided family is not supported (yet). Currently supported are gaussian and binomial.")
         })
  return(list(x = xw, y = yw))
}


sandwich.var.est.stderr <- function(x,y,betainit,Z){
  ## Purpose:
  ## an implementation of the calculation of the robust standard error
  ## based on the sandwich variance estimator from
  ## http://arxiv.org/abs/1503.06426
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## x: the design matrix
  ## y: the response vector
  ## betainit: the initial estimate
  ## Z:       the residuals of the nodewise regressions
  ## ----------------------------------------------------------------------
  ## Return values:
  ## se.robust: the robust estimate for the standard error of the corresponding de-sparsified lasso fit
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 18 Mai 2015 (initial version)

  n <- nrow(x)
  p <- ncol(x)

  ## Check if normalization is fulfilled
  if(!isTRUE(all.equal(rep(1, p), colSums(Z * x) / n, tolerance = 10^-8))){
    ## no need to print stuff to the user, this is only an internal detail
    rescale.out <- score.rescale(Z = Z, x = x)
    Z <- rescale.out$Z
    ## scaleZ <- rescale.out$scaleZ
  }

  if(length(betainit) > ncol(x)){
    x <- cbind(rep(1,nrow(x)),x)
  }else{
    if(all(x[,1]==1)){
      ## ok, we have included the intercept
    }else{
      ## hmm, should we substract the mean from y?
    }
  }
  eps.tmp <- as.vector(y - x%*%betainit)

  ## should these esp.tmp be forced to have mean 0?
  ##YES! as if we fit with intercept
  eps.tmp <- eps.tmp-mean(eps.tmp)
  
  sigmahatZ.direct <- sqrt(colSums(sweep(eps.tmp*Z, MARGIN = 2,
                                         STATS = crossprod(eps.tmp,Z)/n,
                                         FUN = `-`)^2))
  ## rm(eps.tmp)
  ## return se.robust :
  sigmahatZ.direct/n ## this is the s.e. of bproj from pval.score,
  ## if we multiply bproj with 1/this, we get on the N(0,1) scale
}

do.initial.fit <- function(x,y,
                           initial.lasso.method = c("scaled lasso","cv lasso"),
                           lambda,
                           verbose = FALSE)
{
  ## Purpose:
  ## This function performs the initial fit of the high dimensional linear model
  ## used in ridge.proj and lasso.proj
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## x: the design matrix
  ## y: the response vector
  ## initial.lasso.method: the method to use to tune the lasso
  ## lambda: OPTIONAL, the tuning parameter for the lasso. If this is provided,
  ##         it overrides initial.lasso.method
  ## verbose: let's you know if the user is overriding initial.lasso.method with a value for lambda
  ## ----------------------------------------------------------------------
  ## Return values:
  ## betalasso: the lasso coefficients, excluding the intercept
  ## sigmahat: estimate for the noise standard  deviation
  ## intercept: intercept, in case the lasso was fitted with it
  ## lambda: the tuning parameter for the lasso that was used, not available for the scaled lasso
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 16 Oct 2015 (initial modified version for the package)

  no.lambda.given <- missing(lambda) || is.null(lambda)
  if(!no.lambda.given && verbose) {
    cat("A value for lambda was provided to the do.initial.fit function,\n")
    cat("the initial.lasso.method option was therefore ignored.\n")
    cat("We now do a lasso with the tuning parameter instead of a self-tuning procedure.\n") 
  }

  if(no.lambda.given){
    ## tune the lasso
    switch(initial.lasso.method,
           "scaled lasso"={
             scaledlassofit <- scalreg(X=x,y=y)
             lambda <- NULL## no way to extract lambda for this ?
           },
           "cv lasso"={
             glmnetfit <- cv.glmnet(x=x,y=y)
             lambda <- glmnetfit$lambda.1se
           },
           {
             stop("Not sure what lasso.method you want me to use for the initial fit. The only options for the moment are: 1)scaled lasso 2)cvlasso")
           })
  }else{
    ## fit for a range of lambda
    glmnetfit <- glmnet(x=x,y=y)
  }

  if(no.lambda.given && identical(initial.lasso.method,"scaled lasso")){
    intercept <- 0
    betalasso <- scaledlassofit$coefficients
    sigmahat  <- scaledlassofit$hsigma
    residual.vector <- y-x%*%betalasso
  }else{
    if((nrow(x) - sum(as.vector(coef(glmnetfit, s = lambda)) != 0)) <= 0){
      ## Problem: when the fixed lambda you chose sets n==p, you've used all
      ## your degrees of freedom 
      ##- -> refit
      ## This only occurs if the user provides a lambda to use
      message("Refitting using cross validation: your lambda used all degrees of freedom")
      glmnetfit <- cv.glmnet(x=x,y=y)
      ## setting a lambda here would interpolate solutions, :/
      lambda <- glmnetfit$lambda.1se
    }

    intercept <- coef(glmnetfit,s=lambda)[1]
    betalasso <- as.vector(coef(glmnetfit,s=lambda))[-1]## leaving out the intercept
    residual.vector <- y-predict(glmnetfit,newx=x,s=lambda)
    sigmahat <- sqrt(sum((residual.vector)^2)/
                     (nrow(x)-sum(as.vector(coef(glmnetfit,s=lambda))!=0)))
  }
  ## return
  list(betalasso=betalasso,
       sigmahat=sigmahat,
       intercept=intercept,
       lambda=lambda)
}

initial.estimator <- function(betainit,x,y,sigma)
{
  ## check if betainit is correctly provided
  if(!((is.numeric(betainit) && length(betainit) == ncol(x)) ||
       (betainit %in% c("scaled lasso","cv lasso"))))
  {
    stop("The betainit argument needs to be either a vector of length ncol(x) or one of 'scaled lasso' or 'cv lasso'")
  }

  warning.sigma.message <- function() {
    warning("Overriding the error variance estimate with your own value. The initial estimate implies an error variance estimate and if they don't correspond the testing might not be correct anymore.") 
  }

  lambda <- NULL
  
  if(is.numeric(betainit))
  {
    beta.lasso <- betainit

    if(is.null(sigma))
    {
      stop("Not sure what variance estimate to use here")
      ## if betainit comes from the lasso, the below should be good
      residual.vector <- y- x%*%betainit
      sigmahat <- sqrt(sum((residual.vector)^2)/
                       (nrow(x)-sum(betainit!=0)))
    }else{
      warning.sigma.message()
      sigmahat <- sigma
    }
  }else{
    initial.fit <- do.initial.fit(x=x,y=y,
                                  initial.lasso.method=betainit)
    beta.lasso <- initial.fit$betalasso

    lambda <- initial.fit$lambda
    
    if(is.null(sigma))
    {
      sigmahat <- initial.fit$sigmahat
    }else{
      warning.sigma.message()
      sigmahat <- sigma
    }
  }
  ## return
  list(beta.lasso = beta.lasso,
       sigmahat = sigmahat,
       lambda = lambda)
}

prepare.data <- function(x, y, standardize, family)
{
  ## *center* (scale) the columns
  x <- scale(x, center = TRUE, scale = standardize)
  
  dataset <- switch(family,
                    "gaussian" = {
                      list(x = x, y = y)
                    },
                    {
                      switch.family(x = x, y = y,
                                    family = family)
                    })
  
  ## center the columns and the response to get rid of the intercept
  x <- scale(dataset$x, center = TRUE, scale = FALSE)
  y <- scale(dataset$y, scale = FALSE)
  y <- as.numeric(y)
  list(x=x,y=y)
}

despars.lasso.est <- function(x, y, Z,
                              betalasso)
{
  ## Purpose:
  ## The desparsified Lasso estimator
  ## This code allows for Y and betalasso to be matrices, which is useful
  ## when computing this for the bootstrap
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## x: the design matrix
  ## y: the response vector or matrix of response vectors
  ## betalasso: the initial estimate or matrix of initial estimate vectors
  ## Z:       the residuals of the nodewise regressions
  ## ----------------------------------------------------------------------
  ## Return values:
  ## b: the de-sparsified Lasso estimates
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 15 June 2016 (initial version)
  ## Based on older private code
  
  b <- crossprod(Z,y-x%*%betalasso)/nrow(x) + betalasso
  if(ncol(b) == 1)
    b <- as.vector(b)
  b
}

est.stderr.despars.lasso <- function(x, y, Z,
                                     betalasso, sigmahat,
                                     robust,
                                     robust.div.fixed = FALSE)
{
  ## Purpose:
  ## estimate the standard error (either robust or non-robust) for the desparsified Lasso estimator
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## x: the design matrix
  ## y: the response vector or matrix of response vectors
  ## Z:       the residuals of the nodewise regressions
  ## betalasso: the initial estimate or matrix of initial estimate vectors
  ## sigmahat: estimate for the noise standard  deviation
  ## robust: if the standard error should be the robust version or the non-robust version
  ## robust.div.fixed: if we should use the 1/n standardization or 1/(n-hat(s))
  ## ----------------------------------------------------------------------
  ## Return values:
  ## stderr: the estimate for the standard error of the corresponding de-sparsified lasso fit
  ## ----------------------------------------------------------------------
  ## Author: Ruben Dezeure, Date: 15 June 2016 (initial version)
  ## Based on older private code
  
  if(robust){    
    stderr <- sandwich.var.est.stderr(x=x,y=y,Z=Z,
                                      betainit=betalasso)
    n <- nrow(x)

    if(robust.div.fixed)
      stderr <- stderr*n/(n-sum(betalasso!=0))
  }else{    
    stderr <- (sigmahat*sqrt(diag(crossprod(Z))))/nrow(x)    
  }
  
  stderr  
}

boot.initial.fit <- function(x,
                             ystar,
                             betainit,
                             lambda,
                             parallel,
                             ncores)
{
  if(is.numeric(betainit))
    stop("We need to somehow specify the initial lasso method for the bootstrap!")
  args <- list(FUN = do.initial.fit,
               x = list(x = x),
               y = split(ystar, col(ystar)),
               initial.lasso.method = betainit,
               SIMPLIFY = FALSE,
               mc.cores = ncores)
  
  if(!is.null(lambda))## Implement the bootstrap shortcut
    args <- c(args, list(lambda = lambda))
  
  out.init.star <- do.call(mcmapply,
                           args = args)  
}

boot.se <- function(x,
                    ystar,
                    Z,
                    betainitstar,
                    sigmahatstar,
                    robust,
                    robust.div.fixed = FALSE,
                    parallel,
                    ncores)
{
  if(robust)
  {
    sestar <- mcmapply(est.stderr.despars.lasso,
                       x = list(x = x),
                       y = split(ystar, col(ystar)),
                       Z = list(Z = Z),
                       betalasso = split(betainitstar, col(betainitstar)),
                       sigmahat = sigmahatstar,
                       robust = robust,
                       robust.div.fixed = robust.div.fixed,
                       mc.cores = ncores)
  }else{
    sestar <- outer(sqrt(colSums(Z^2))/nrow(x),
                    sigmahatstar)
  }
  
  sestar
}

resample <- function(r,
                     B,
                     wild)
{
  if(wild)
  {
    Ui <- replicate(B,rnorm(length(r)))
    rs <- r * Ui
  }else{
    rs <- replicate(B,
                    sample(r, replace=TRUE))
  }
  rs
}

# ---- R/methods.R (print.hdi, lines 1-83; confint.hdi, lines 180-237) ----------
hdi_print.hdi <- function(x, ...)
{
  ## Purpose:
  ## ----------------------------------------------------------------------
  ## Arguments:
  ## ----------------------------------------------------------------------
  ## Author: Lukas Meier, Date:  3 Apr 2013, 15:12

  method <- if(is.list(x)) x$method else ""

  #####################
  ## Multi-Splitting ##
  #####################

  if(method == "multi.split"){
    cat("alpha = 0.01:")
    cat(" Selected predictors:", which(x$pval.corr <= 0.01), "\n")
    cat("alpha = 0.05:")
    cat(" Selected predictors:", which(x$pval.corr <= 0.05), "\n")
    cat("------\n")
    cat("Familywise error rate controlled at level alpha.\n")
  }

  ###############
  ## Stability ##
  ###############

  else if(method == "stability"){
    cat("Selected predictors:\n")
    cat("--------------------\n")
    if(is.null(x$select)){
      cat("none\n")
    }else{
      print(x$select)
    }

    ##for(i in 1:length(x$select)){
    ##  cat("EV = ", x$EV[[i]], ":", sep = "")
    ##  cat(" Selected predictors:", x$select[[i]], "\n")
    #}
    cat("--------------------\n")
    cat("Expected number of false positives controlled at level", x$EV, "\n")
  }

  #########################
  ## Cluster Lower-Bound ##
  #########################

  else if(method == "clusterGroupBound"){
    cat("lower l1-norm group bounds in a hierarchical clustering:")
    cat("\n- lower bound on l1-norm of *all* regression coefficients:",
        signif(max(x$lowerBound),4))

    leaf.p.bnd <- x$isLeaf & x$lowerBound > 0
    if(sum(leaf.p.bnd) == 1){
      tmp <- sum(x$noMembers[which(leaf.p.bnd)])
      cat("\n- only 1 significant non-overlapping cluster with", tmp ,
          if(tmp == 1) "member" else "members")
    }else{
      cat("\n- number of non-overlapping significant clusters:",
          sum(leaf.p.bnd))
      tmp <- range(x$noMembers[which(leaf.p.bnd)])
      if(diff(tmp) == 0){
        cat("\n  (with", tmp[1],
          if(tmp[1] == 1) "member in each non-overlapping cluster)" else
            "members in each non-overlapping cluster)")
      }else{
        cat("\n  (with", paste(tmp, collapse = " "), "members each)")
      }
    }
    cat("\n ")
  }

  ######################
  ## Other situations ##
  ######################

  else{
    print.default(x, ...)
  }
  
  invisible(x) # as *every* print() method
}
## not on any help page yet:
hdi_confint.hdi <- function(object, parm, level = 0.95, ...)
{
  ## Author: Lukas Meier, Date: 27 Jun 2014, 11:30
  
  meth <- object$method
  obj <- switch(meth,
                "lasso.proj"  = object$bhat,
                "boot.lasso.proj"  = object$bhat,
                "ridge.proj"  = object$bhat,
                "multi.split" = object$pval.corr,
                ## otherwise :
                stop("Not supported object type ", meth))
  
  pnames <- if(is.null(names(obj))) seq_along(obj) else names(obj)
  if(missing(parm))
    parm <- pnames
  else if (is.numeric(parm))
    parm <- pnames[parm]

  if(meth %in% c("lasso.proj", "ridge.proj")){
    quant <- qnorm(1 - (1 - level) / 2)
    delta <- if(meth == "ridge.proj") object$delta[parm] else 0
    add   <- object$se[parm] * (quant + delta)
    m     <- cbind(obj[parm] - add,
                   obj[parm] + add)
  }
  else if(meth == "multi.split") {
    if(is.na(object$ci.level))
      stop("No confidence interval information available in fitted object")
    if(!missing(level) && level != object$ci.level)
      warning("Ignoring argument 'level', using 'ci.level' of fitted object")
    m <- cbind(object$lci[parm],
               object$uci[parm])
  } else if(meth == "boot.lasso.proj"){
    if(is.null(object$cboot.dist))
    {
      stop("Bootstrap output is missing the bootstrap distribution necessary to compute confidence intervals. Rerun the bootstrap with the correct options to pass on the bootstrap distribution.")
    }

    alpha <- 1 - level
    
    if((alpha/2 * object$B)%%1 == 0)
    {
      quantile.type <- 1
    }else{
      quantile.type <- 7##this is the default
    }
    
    qstar <- apply(object$cboot.dist,1,quantile,probs=c(alpha/2,1-alpha/2),
                   type=quantile.type)
    m <- cbind(obj[parm] - qstar[2,parm],
                obj[parm] - qstar[1,parm])
  }

  dimnames(m) <- list(parm, c("lower", "upper"))
  m
}
