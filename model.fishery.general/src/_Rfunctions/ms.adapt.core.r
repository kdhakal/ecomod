
ms.adapt.core = function(inits, ... ) {
  # unpack parameters
    ages = V$ages
    years = V$years
    nages = length(ages)
    nyears = length(years)
    aX = c( nages-1, nages) # indices of the last 2 age classes (8 plus group and age 7)
    yX = nyears    # the index of the last year
    a = c(1:(nages-2))
    y = c(1:(nyears-1))

    # params from RV -series
    years.rv = V$years.rv
    nyears.rv = length(years.rv)
    commonyears= intersect(years, years.rv)
    y.common.rv = which( years %in% commonyears ) 
    
  # general seperable VPA
  F.age = inits[1:nages]
  F.year = inits[(nages+1):length(inits)]
  V$F = V$catch * NA # intialise
  V$F[ aX , ] = F.year
  V$F[ , yX ] = F.age
  V$S = cohort.analysis( V$catch, V$F, V$M )
  V$F[ a,y ] = log( V$S[ a, y] / V$S[ a+1, y+1]) - V$M[ a ] # update F estimates after convergence

  # add error from CPUE indices
  V$catchability = log( V$S[,y.common.rv] ) - log( V$rv )
  V$q = as.matrix( rowMeans( V$catchability, na.rm=T ) )
  V$resids.cpue = V$catchability - V$q[,]

  V$error = sum( V$resids.cpue^2, na.rm=T)
  return( V )
 }


