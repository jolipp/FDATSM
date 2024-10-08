#' @title Truncated covariation estimator
#' @description This function computes a truncated estimator of covariation for a given matrix of discount curve data
#' @param x x[i,j] is the discount curve data at thje i-th time point and j-th maturity
#' @param tq Quantile at which the data are truncated for the preliminary covariation estimate
#' @param l Truncation level
#' @param sumplot sumplot = TRUE produces a summary plot
#'
#' @return Returns a list which contains:
#'   \item{IV}{The truncated covariation matrix}
#'   \item{locs}{The locations of the identified jumps in price data}
#'   \item{C.Prel}{The preliminary estimator of covariation}
#'   \item{adj.increments}{The matrix of adjusted increments used for estimation}
#'   \item{expl.var}{The explained variation based on the eigenvalues of the truncated covariation matrix}
#' @export
Truncated.Covariation.estimator <- function(x,# discount curve data x[i,j]=p_{i\Delta}(j\Delta)
                                           tq = 0.75, ## the quantile at which
                                           #################the data are truncated for the preliminary
                                           #################covariation estimate. The estimator is then
                                           #################rescaled such that the first eigenvalue of
                                           #################the preliminary estimator corresponds to
                                           #################correspond to the interquartile estimate
                                           l = 3,
                                           sumplot = TRUE
){
  n= nrow(x) #number of days in which discount curves are considered
  m= ncol(x) #number of days in the maturity direction

  log.prices<-log(x)
 adjusted.increments<-matrix(0,n-1,m-2)  #adjusted increment= log(x[i+1, j])-log(x[i, j+1])-log(x[i+1, j-1])+log(x[i, j])

  for(i in 1:(n-1)){
    adjusted.increments[i,1:(m-2)]<-diff(log.prices[(i+1),1:(m-1)])-diff(log.prices[i,2:m])
  }

  ######Now conduct the truncation procedure
  #Start with the preliminary estimator for the quadratic variation


{  rough.locs<-quantile.truncation(adjusted.increments,tq)
  C.Prel<-Variation(adjusted.increments[-rough.locs,])


  EG<-eigen(C.Prel)
  EG.rough.vectors<-EG$vectors

  VALUES<-numeric(n-1)# loadings of the first eigenvalue
    for (i in 1:(n-1)) {
      VALUES[i]<-t(EG$vectors[,1])%*%adjusted.increments[i,]
    }
    q.75<-as.numeric(quantile(VALUES,0.75))
    q.25<-as.numeric(quantile(VALUES,0.25))
    rho.star<-((q.75-q.25)^2)/((4*(qnorm(0.75)^2)*EG$values[1])/n)#interquartile range estimator for variance of first eigenvector loadings

    C.Prel<-rho.star*C.Prel
}#calculates the preliminary estimator for the realized covariation

    locs<-Functional.data.truncation(d = d.star(C=C.Prel,tq),C= C.Prel, data =   adjusted.increments, Delta = 1/n,  sd =l)$locations


  if(length(locs) == 0){
    Truncated.variation<-Variation(adjusted.increments)/(n^2)
  }
  if(length(locs) != 0){
    Truncated.variation<-Variation(adjusted.increments[-locs,])/(n^2)
  }

    #Calculate factor loadings
    loads<-numeric(ncol(Truncated.variation))
    EG2<-eigen(Truncated.variation)
    for (i in 1:ncol(Truncated.variation)) {
      loads[i]<-sum(EG2$values[1:i])
    }
    expl.var<-loads/sum(EG2$values)


    if(sumplot == TRUE){
      #calculate norms
      norms<-numeric(n)
      for (i in 1:n) {
        norms[i]<-L2.norm(x[i,])
      }
      adj.norms<-numeric(n-1)
      for (i in 1:(n-1)) {
        adj.norms[i]<-L2.norm(adjusted.increments[i,])
      }
      par(mfrow = c(2, 2))
      persp(Truncated.variation,xlab= "Time to maturity (years)")
      plot(expl.var[1:10], type = "p", ylab = " Explained Variation", xlab = "Nr. of eigenvalues")
      abline(h = .99, col = "gray60")
      plot(norms, type = "l", ylab = "L2 norms of price curves", xlab = "time", xaxt = "n")
      axis(side = 1, c(10,20,30,40,50,60,70,80,90,99), c(10,20,30,40,50,60,70,80,90,99))
      points(x=locs, y= norms[locs], col = "darkgreen")

      plot(adj.norms, type = "l", ylab = "L2 norms of difference returns", xlab = "time", xaxt = "n")
      axis(side = 1, c(10,20,30,40,50,60,70,80,90,99), c(10,20,30,40,50,60,70,80,90,99))
       points(x=locs, y= adj.norms[locs], col = "darkgreen")
    }

    locs<-locs+1 #To match the locations of the jumps price data
  return(list("IV" = Truncated.variation, "locs" = locs, "C.Prel" =C.Prel, "adj.increments" = adjusted.increments, "expl.var" =expl.var))
}

