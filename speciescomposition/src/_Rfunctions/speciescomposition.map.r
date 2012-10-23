
  speciescomposition.map = function( ip=NULL, p, type="annual" ) { 

    if (!is.null(p$init.files)) for( i in p$init.files ) source (i)
    if (is.null(ip)) ip = 1:p$nruns
		
    require( lattice )
    require (grid)
    
     
    if ( type=="annual" ) {
      for ( iip in ip ) {
        y = p$runs[iip,"yrs"]
        v = p$runs[iip,"vars"]
        modtype= p$runs[iip,"modtype"]
        
        ddir = file.path( project.directory("speciescomposition"), "maps", p$spatial.domain, modtype, p$taxa, p$season, type  )
        dir.create(path=ddir, recursive=T, showWarnings=F)

        sc = speciescomposition.interpolate ( p=p, yr=y, modtype=modtype ) 
        sc = sc[ filter.region.polygon( sc, region=c("4vwx", "5yz" ), planar=T, proj.type=p$internal.projection ) , ]
        outfn = paste( v, y, sep=".")
        annot = paste("Species composition: ", toupper(v), " (", y, ")", sep="")
        
        if (v=="ca1") dr=c(-2,2)
        if (v=="ca2") dr=c(-4,2)
        if (v=="pca1") dr=c(-0.5, 0.5)
        if (v=="pca2") dr=c(-0.5, 0.5)
        
        if (is.null(dr)) dr = range(sc[,v], na.rm=T)
        
        datarange = seq( dr[1], dr[2], length.out=100 )
      
        # levelplot( ca1 ~ plon+plat, sc, aspect="iso")
        xyz = sc[, c("plon","plat",v)]
        map( xyz=xyz, cfa.regions=F, depthcontours=T, pts=NULL, annot=annot, fn=outfn, loc=ddir, at=datarange , 
          col.regions=color.code( "blue.black", datarange ), corners=p$corners )
      }
    }

  }


