
  interpolation.db = function( ip=NULL, DS, p=NULL ) {
    
    if ( DS %in% c( "interpolation.redo", "interpolation", "interpolation.simulation", "interpolation.simulation.redo", "interpolation.simulation.complete", "interpolation.simulation.PS" ) ) {
     
      basedir = file.path( project.directory("snowcrab"), "R", "gam" )

      loc.map = file.path( basedir, "maps" )
      loc.sol = file.path( basedir, "predictions" )
      loc.res = file.path( basedir, "results" )
     
      dir.create(path=loc.map, recursive=T, showWarnings=F)
      dir.create(path=loc.sol, recursive=T, showWarnings=F)
      dir.create(path=loc.res, recursive=T, showWarnings=F)
  
      require (lattice)
      require (grid)

         
      if( DS=="interpolation.simulation.complete") {
        load( p$ofname )
        return( K ) 
      }

      if (!is.null(p$env.init)) for( i in p$env.init ) source (i)
      if (is.null(ip)) ip = 1:p$nruns
    
      if (DS %in% c("interpolation.simulation")  ) {
        out = NULL
        for ( iip in ip ) {
          y = p$runs[iip,"y"]
          v = p$runs[iip,"v"]
          fn.K = file.path( loc.res, paste( "K", v, y, "rdata", sep="." ) )
          if ( ! (file.exists( fn.K)) ) next()
          load(fn.K)

				# this is a temporary fix for when data are not all properly refreshed
          oo = names(out)
					kk = names(K)
					
					if ( length(oo) > length(kk) ) {
						a = out 
						b = K
					} else {
						a = K
						b = out 
					}

					oo = setdiff( names(a), names(b) )
					if ( !is.null(out) && (length( oo ) > 0) ) {
						newvars = setdiff( names(a), names(b) )
						b[,newvars] = NA
						b = b[, names(a) ]
						out = rbind( a, b)

					} else {
						out = rbind( out, K )
					}

        }  
        K = out
        save( K, file=p$ofname, compress=T )  # glue all the data results together into one file
        return ( K )
      }

      if (DS=="interpolation.simulation.PS" ) {
        out = NULL
          v = p$v
          y = p$y
          fn.PS = file.path( loc.sol, paste( "PS.simulation.means", v, y, "rdata", sep="." ) )
          if ( ! (file.exists( fn.PS)) ) return(NULL)
          load(fn.PS)
        return (PS)
      }
      
      K = NULL

      for ( iip in ip ) {

        y = p$runs[iip,"y"]
        v = p$runs[iip,"v"]

        qs = empirical.ranges( db="snowcrab", v, probs=c(p$habitat.threshold.quantile, 0.95), remove.zeros=T ) 
  
        PS = habitat.db ( DS="complete", year=y, p=p )
				PS$weekno = p$prediction.weekno  # must be same as above
				PS$t = NA
         
        PST = hydro.db( p=p, DS="spatial.interpolation", yr=y  )
				if (is.null(PST)) next ()
				
        PS$t = PST[, p$prediction.weekno ]
        PS$t[ which(PS$t < -2) ] = -2
			  PS$t[ which(PS$t > 30) ] = 30 

        iitna = which( ! is.finite( PS$t ) ) 
        if (length(iitna)>0) PS$t[iitna] = PS$tmean.annual[iitna]

        PS$z = log(PS$z)
        PS$dt.seasonal = PS$tmean.annual - PS$t 
        PS$dt.annual = PS$tmean - PS$tmean.annual
        PS$sa = 1

				# posterior simulations
				Hmodel = habitat.model.db( DS="habitat", v= v )
				Hsim = gam.simulation( M=Hmodel, X= PS, nsims=p$nsims ) #~8min
        rm( Hmodel); gc()
			  
        oops = which( is.na(Hsim) ) 
        if (length(oops) > 0)  Hsim[oops ] = 0  # assume to be zero
        #Hsim = round(Hsim)  # force binary

				Amodel = habitat.model.db( DS="abundance", v=v )
        Asim = gam.simulation( M=Amodel, X= PS, nsims=p$nsims ) # ~5min
	      rm( Amodel); gc()
		
        oops = which( is.na(Asim) ) 
        if (length(oops) > 0)  Asim[oops ] = 0  # assume to be zero

        # Do not extrapolate: trim to XX% quantiles to be a little more conservative
        oopu =  which( Asim > qs[2] )
        if (length(oopu) > 0)  Asim[ oopu ] = qs[2]
       
        oopl =  which( Asim < qs[1]  )
        if (length(oopl) > 0)  Asim[ oopl ] = 0  # below detection limits
  
        Asim = Asim * Hsim  # Asim now becomes weighted by Pr of habitat
				
				Hsim.sa = colSums( Hsim ) # Pr weighted sum of habitat 
				totalsurfacearea = mean ( Hsim.sa ) * (p$pres*p$pres)
        totalsurfacearea.sd = sd( Hsim.sa ) * (p$pres*p$pres)
        rm ( Hsim.sa ); gc()

        PS$habitat.mean = apply( Hsim, 1, mean, na.rm=T )
        PS$habitat.sd = apply( Hsim, 1, sd, na.rm=T )
			  
        PS$abundance.mean = apply( Asim, 1, mean, na.rm=T ) 
        PS$abundance.sd =  apply( Asim, 1, sd, na.rm=T )

        # iAbundance = which ( PS$abundance.mean >= qs[1] )  #  consider abundance only if it is sufficiently precise (low associated variance)
        # iHabitat = which( PS$habitat.mean >= 0.5 )        #  consider habitat only if p>0.5
        # iHabitat = which( (PS$habitat.mean - 2*PS$habitat.sd) > 0 )   #  consider habitat only if it is sufficiently precise (low associated variance)
        # iHabitat = which( PS$habitat.mean > 0 )
        iHabitat = which( PS$habitat.mean > p$habitat.threshold.quantile  & (PS$habitat.mean - 2 * PS$habitat.sd) > 0 )

        iStations = filter.prediction.locations( DS="limit.to.near.survey.stations", PS=PS, y=y, p=p )  # consider locations only if close to a survey location (minimal extrapolation)
        # iHA = intersect(iHabitat, iAbundance)  # good locations for habitat and abundance prediction
				iE = union( iStations, intersect(iHabitat, iStations ))  #  good locations for habitat and abundance prediction, but filtered for proximity to survey stations
				rm( iStations); gc()
 
        # levelplot( habitat.mean ~ plon + plat, data=PS[,], aspect="iso" )
        # levelplot( habitat.mean ~ plon + plat, data=PS[iHA,], aspect="iso" )
        # levelplot( habitat.mean ~ plon + plat, data=PS[iE,], aspect="iso" )

        fn.res = file.path( loc.sol, paste( "PS.simulation.means", v, y, "rdata", sep="." ) )
        print (fn.res )
        save( PS, file=fn.res, compress=T )

        K = NULL
      
        fn.K = file.path( loc.res, paste( "K", v, y, "rdata", sep="." ) )
        print(fn.K)
        
        PS$abundance.mean.log = log10( PS$abundance.mean )  # only used for plotting
        er = log10( qs  )
        
        PS$abundance.mean.log [ which( PS$abundance.mean.log < er[1] ) ] = er[1] 
        # levelplot( abundance.mean.log ~ plon + plat, data=PS, aspect="iso" )
       
        if ("map.habitat" %in% p$ItemsToMap ) {
          datarange = seq( 0, 1, length.out=150)
          cols = color.code( "seis", datarange )
          outfn = paste( "prediction.habitat.mean", v, y, sep=".")
          map( xyz=PS[,c("plon", "plat", "habitat.mean")], cfa.regions=T, depthcontours=T, pts=NULL, annot=paste( v, y ), 
            annot.cex=p$annot.cex, corners=planar.corners, fn=outfn, loc=loc.map, at=datarange, 
            col.regions=cols, rez=c(p$pres,p$pres) )
        }
          
        if ("map.abundance" %in% p$ItemsToMap ) {
          datarange = seq( er[1], er[2], length.out=150)
          cols = color.code( "seis", datarange )
          outfn = paste( "prediction.abundance.mean", v, y, sep=".")
          map( xyz=PS[ , c("plon", "plat", "abundance.mean.log")], cfa.regions=T, depthcontours=T, pts=NULL, annot= paste( v, y ), 
            annot.cex=p$annot.cex, corners=planar.corners, fn=outfn, loc=loc.map, at=datarange, 
            col.regions=cols, rez=c(p$pres,p$pres) )
        }

        if ("map.abundance.estimation" %in% p$ItemsToMap ) {
          tomap = NULL
          tomap = PS[ , c("plon", "plat", "abundance.mean.log")]
          tomap$abundance.mean.log[ setdiff( 1:nrow(PS), iE ) ] = log10( er[1] ) - 1  # just a value smaller than the lower bound
          datarange = seq( er[1], er[2], length.out=150)
          cols = color.code( "seis", datarange )
          outfn = paste( "prediction.abundance.mean.estimationarea", v, y, sep=".")
          map( xyz=tomap, cfa.regions=T, depthcontours=T, pts=NULL, 
            annot=paste( v, y ), annot.cex=p$annot.cex, corners=planar.corners, fn=outfn, loc=loc.map, at=datarange, 
            col.regions=cols, rez=c(p$pres,p$pres) )
          rm (tomap) ; gc()
        }
				
        PS$abundance.mean.log = NULL
				gc()

        for (r in p$regions ){

          iRegion.PS = filter.region.polygon(x=PS[ , c("plon", "plat")], region=r, planar=T)
          iEastof250 = which( PS$plon > 250 )
          iRegion.PS = intersect( iRegion.PS, iEastof250 )
						
					iHabitatSubarea = intersect( iRegion.PS, iHabitat ) # plotting surface and real habitat area
          iEstimationArea = intersect( iRegion.PS, iE )

          if ( length( iEstimationArea ) > 10 ) {

            hhsum = colSums(  Hsim[ iHabitatSubarea , ] ) # area weighted by Pr
            sa.region = mean( hhsum ) * (p$pres*p$pres)
            sa.sd = sd( hhsum ) * (p$pres*p$pres)
              
            hhsum = colSums( Hsim[ iEstimationArea , ] )
            sa.estim = mean( hhsum ) * (p$pres*p$pres)
            sa.estim.sd = sd( hhsum ) * (p$pres*p$pres)

            aa.sums = apply( Asim[ iEstimationArea,  ] , 2, sum ) # abundance weighted by Pr
            V.mean = mean( aa.sums )
            V.sd = sd( aa.sums )
            V.sd.ln = sd( log( aa.sums ), na.rm=T )
            ci = quantile( aa.sums, probs=c(0.025, 0.5, 0.975), na.rm=T,names=F )
          
          } else {
            V.mean = NA
            V.sd = NA
            V.sd.ln = NA
            sa.estim = NA
            sa.estim.sd = NA
            sa.region = NA
            sa.sd = NA
            ci = rep( NA, 3 )
          }

          bb.sums = apply( Asim[ iHabitatSubarea,  ] , 2, sum ) # abundance weighted by Pr
          W.mean = mean( bb.sums )
          W.sd = sd( bb.sums )
          W.ci = quantile( bb.sums, probs=c(0.025, 0.5, 0.975), na.rm=T,names=F )
 
          L = data.frame( yr=y, vars=v, region=r, 
              total=V.mean, total.sd=V.sd, total.sd.ln=V.sd.ln, median=ci[2], lbound=ci[1], ubound=ci[3],
              ss=W.mean, ss.sd=W.sd, ss.median=W.ci[2], ss.lbound=W.ci[1], ss.ubound=W.ci[3],
              sa.total=totalsurfacearea, sa.total.sd=totalsurfacearea.sd,
              sa.region=sa.region, sa.region.sd=sa.sd, 
              sa.estimation=sa.estim, sa.estimation.sd=sa.estim.sd,

              datestamp=as.character( Sys.time() ) )
          K = rbind( K, L )    
        } # regions
        
        save(K, file=fn.K, compress=T)
        print (K)
        print( "... Completed successfully" )  

      } # runs (ip)
    } # end if interpolations...  

    return ("Completed" )
  }


