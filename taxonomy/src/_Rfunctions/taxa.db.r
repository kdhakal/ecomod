

  taxa.db = function( DS="complete", itis.taxa.lowest="species", parallelrun=T, find.parsimonious.spec=T ) {

    if ( DS == "gstaxa" ) return( taxa.db( "life.history") )  

    if ( DS %in% c("spcodes", "spcodes.redo"  ) ) {
      
      if ( DS == "spcodes" ) {
        spcodes = groundfish.db( DS="spcodes.odbc" ) 
        return( spcodes )
      }
      
      groundfish.db( DS="spcodes.odbc.redo" ) 
      return ( fn )
    }
 
    if (DS %in% c("spcodes.itis", "spcodes.itis.redo", "spcodes.itis.parsimonious" )) {
      
			print( "" )
			print( "Warning:: spec = bio species codes -- use this to match data but not analysis" )
			print( "          spec.clean = manually updated codes to use for taxonomic work in gstaxa_taxonomy.xls/csv" )
			print( "" )
			
			# add itis tsn's to spcodes -- this completes the lookup table
			# a partial lookup table exists and is maintained locally but then is added to using 
			# text matching methods, which are a bit slow.

      fn = file.path( project.directory("taxonomy"), "data", "spcodes.itis.rdata" )
      fnp = file.path( project.directory("taxonomy"), "data", "spcodes.itis.parsimonious.rdata" )
      
      if ( DS =="spcodes.itis") {
        load(fn)
        return (spi)
      }
      
      if ( DS =="spcodes.itis.parsimonious") {
        load(fnp)
        return (spi)
      }
     
      
      spi = taxa.db( DS="spcodes" )
      names(spi) = tolower( names(spi) )
      
      spi$name.common = as.character( spi$comm )
      spi$name.scientific = as.character( spi$spec )
      spi$spec = as.numeric(spi$code)
      spi = spi[ , c("spec", "name.common", "name.scientific" ) ]
      spi$tolookup = TRUE
      spi$flag = ""
			
			# update tsn's directly using any local corrections/additions
			# these have been manually verified: http://www.itis.gov/servlet/SingleRpt/SingleRpt
			# these also help speed up the lookup through itis as that is slow

			print( "Updating from manually verified tsn/spec codes:")
			print( "maintained in file: gstaxa_taxonomy.xls/csv -- must be'|' delimited and 'quotes used for export' " )
			
			fn.local.taxa.lookup = file.path( project.directory("taxonomy"), "data", "gstaxa_taxonomy.csv" )
			tx.local = read.table( file=fn.local.taxa.lookup, sep="|", as.is=T, strip.white=T, header=T) 
			tx.local = tx.local[, c("spec", "spec.clean", "accepted_tsn", "comments", "name.common.bio")]
			it = which( duplicated( tx.local$spec))
			if (length(it)>0) {
				print ( "Warning: Duplicated spec codes found in gstaxa_taxonomy.csv")
				print ( tx.local[ which(tx.local$spec %in% unique(tx.local$spec[it]) ), ])
				tx.local = tx.local[ -it, ]
			}
			spi.n0 = nrow(spi)
			spi_id = unique( spi$spec )
			spi = merge( spi, tx.local, by="spec", all.x=T, all.y=F, sort=F )
			if ( nrow(spi) != spi.n0 ) {
				print("New species records have been entered via the local lookup table:")
				print( spi[ - which(spi$spec %in% spi_id ), ] ) 
			}

			
			# over write completely as this is the first data layer for the tsn's
			spi$itis.tsn = spi$itis.tsn_manually_maintained = spi$accepted_tsn
			spi$accepted_tsn = NULL
	

			
			# mark nonliving items to not be looked up
			ib = which( spi$itis.tsn == -1  )
			if (length (ib)>0 ) {
				spi$tolookup[ ib] = FALSE
				spi$flag[ib] = "manually rejected"
				spi$itis.tsn[ ib] = NA  # reset to NA
			}
			

			lu = which( is.finite(spi$itis.tsn))
			spi$tolookup[lu] = FALSE
			spi$flag[lu] = "manually determined"
		
			
      #  words to use to flag as not needing a tsn lookup
      wds = c( "eggs", "egg", "reserved",  "remains", "debris", "remains", "stones", "mucus", 
							"bait", "foreign", "fluid", "operculum", "crude", "water", "Unidentified Per Set", 
							"Unidentified Species", "Unid Fish And Invertebrates", "Parasites", "Groundfish", "Marine Invertebrates",
							"Sand Tube" )
      for (w in wds) {
        iv = grep( paste("\\<", w, "\\>", sep=""), spi$name.scientific, ignore.case=T ) 
        iw = grep( paste("\\<", w, "\\>", sep=""), spi$name.common.bio, ignore.case=T ) 
        iw = sort( unique( c(iv, iw) ) )
				spi$tolookup[iw] = FALSE
        spi$flag[iw] = w
      } 
  
			# words to remove -- with punctuation
      wds.toremove = c( "etc\\.", "sps\\.", "unid\\.", "unid", "unidentified", "spp\\.", "sp\\.", "s\\.f\\.", 
											  "sf\\.", "s\\.p\\.", "s\\.o\\.", "so\\.", "s\\.c\\.", "\\(ns\\)",  "o\\.", "f\\.", "p\\.", "c\\." ) 
      for (w in wds.toremove) {
        wgr =  paste("[[:space:]]+", w, sep="")
        spi$name.scientific = gsub( wgr, "", spi$name.scientific, ignore.case=T ) 
        spi$name.common = gsub( wgr, "", spi$name.common, ignore.case=T ) 
			} 

      # words to remove -- with no punctuation 
      wds.toremove = c( "unidentified", "adult", "SUBORDER", "ORDER", "etc", "sp", "spp", "so", "ns",  "c", "p", "o",
											  "f", "s", "obsolete", "berried", "short", "larvae", "larval", "megalops" , "purse" ) 
      for (w in wds.toremove) {
        wgr =  paste("\\<", w, "\\>", sep="")
        spi$name.scientific = gsub( wgr, "", spi$name.scientific, ignore.case=T ) 
        spi$name.common = gsub( wgr, "", spi$name.common, ignore.case=T ) 
			} 

      spi$name.scientific = strip.unnecessary.characters(spi$name.scientific)
      spi$name.common = strip.unnecessary.characters(spi$name.common)


      iToLookup = which( spi$tolookup & !is.finite(spi$itis.tsn )) 

			kingdoms = itis.db( DS="kingdoms")
			kingdoms = sort( kingdoms$kingdom_name  )  # this makes sure Animalia is first .. speeds things up

      for ( k in kingdoms ) { 

				print (k)
				itaxa = itis.db( "itaxa", itis.kingdom=k )
 
        if ( parallelrun ) {

          lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          res = mclapply( lookup, itis.lookup, tx=spi$name.scientific, itaxa=itaxa, mc.preschedule=F  )
          spi$itis.tsn[lookup] = as.numeric( unlist( res ) )
           
					# some vernaculars used in scientific names 
          lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          res = mclapply( lookup, itis.lookup, tx=spi$name.scientific, itaxa=itaxa, type="vernacular", mc.preschedule=F )
          spi$itis.tsn[lookup] = as.numeric( unlist( res ) )

         
          lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          res = mclapply( lookup, itis.lookup, tx=spi$name.common, itaxa=itaxa, type="vernacular", mc.preschedule=F )
          spi$itis.tsn[lookup] = as.numeric( unlist( res ) )

					lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          res = mclapply( lookup, itis.lookup, tx=spi$name.common.bio, itaxa=itaxa, mc.preschedule=F  )
          spi$itis.tsn[lookup] = as.numeric( unlist( res ) )

    
        } else {

          lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          for ( ii in lookup ) {
						jj = itis.lookup(  ii, tx=spi$name.scientific, itaxa=itaxa )          
						if (length(jj) == 1) spi$itis.tsn[ ii] = jj
					}

					# some vernaculars used in scientific names 
					lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          for ( ii in lookup ) {
						jj = itis.lookup(  ii, tx=spi$name.scientific, itaxa=itaxa, type="vernacular" )
						if (length(jj) == 1) spi$itis.tsn[ ii] = jj
					}

					lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          for ( ii in lookup ) {
						jj = itis.lookup(  ii, tx=spi$name.common, itaxa=itaxa, type="vernacular" )
						if (length(jj) == 1) spi$itis.tsn[ ii] = jj
					}

					lookup = intersect( iToLookup, which( !is.finite( spi$itis.tsn ) ) )
          for ( ii in lookup )  {
						jj = itis.lookup(  ii, tx=spi$name.common.bio, itaxa=itaxa )
						if (length(jj) == 1) spi$itis.tsn[ ii] = jj
					}
        }

			}

			# remainder of missing spec.clean points to spec
			i = which( !is.finite(spi$spec.clean) )
			if (length(i)>0) spi$spec.clean[i] = spi$spec[i]

			# now that tsn's have been completed, it is necessary to update the tsn's to reflect the manually set spec.clean 
			i = which( (spi$spec != spi$spec.clean) & spi$tolookup )
			if (length(i)>0) {
				for (j in i) {
					ii = which( spi$spec== spi$spec.clean[j] )
					if (length(ii)>0) spi$itis.tsn[ j ] = spi$itis.tsn[ ii ]
				}
			}

  		# need to go through duplicated tsn's and code them all  spec.clean id's to point to a single spec id (choose min value as default)
			dup.tsn = sort( unique( spi$itis.tsn[ duplicates.toremove( spi$itis.tsn )]  )) 
			for (tsni in dup.tsn) {
				oi = which( spi$itis.tsn ==tsni )
				op = which.min( spi$spec[ oi ] )
				spi$spec.clean[oi] = min( spi$spec[oi[op]],  spi$spec[oi] )
			}

			i = which( !is.finite(spi$itis.tsn) & spi$tolookup ) 
			if (length(i)>0) {
				print( "The following have no itis tsn matches or are duplicated ")
				print( " ... assuming their spec id's are OK" )
				print( "Their tsn's should be manually identified and updated in the local updates file:" )
				print( "gstaxa_taxonomy.csv -- see spcodes.itis.redo, above .. these are stored in " ) 
				print( spi[i,] )
				fn2 = file.path( project.directory("taxonomy"), "data", "spcodes.no.itis.matches.csv" )
				print (fn2 )
				write.csv ( spi[i,], file=fn2 )
			}											 

      save( spi, file=fn, compress=T )

			# find.parsimonious.spec = T
			if (find.parsimonious.spec) {
				# find most parsimonious list of species and place into spec.clean
				spi$spec.parsimonius = taxa.specid.correct( spi$spec )
				psm = which(spi$spec.parsimonius != spi$spec.clean)
				if (length(psm)>0) spi$spec.clean[psm] = spi$spec.parsimonius[psm]

				spi$spec.parsimonius2 = taxa.specid.correct( spi$spec.clean )
				psm2 = which(spi$spec.parsimonius2 != spi$spec.clean)
				if (length(psm2)>0) spi$spec.clean[psm2] = spi$spec.parsimonius2[psm2]
			  
        save( spi, file=fnp, compress=T )
			}

      return ( fn )
    }


    if (DS %in% c("full.taxonomy", "full.taxonomy.redo") ) {
      
      # add full taxonomic hierarchy to spcodes database .. 
			
      itis.taxa.lowest = tolower(itis.taxa.lowest)
      fn = file.path( project.directory("taxonomy"), "data", paste("spcodes", itis.taxa.lowest, "rdata", sep=".") )
      
      if (DS=="full.taxonomy") {
        load(fn)
        return(spf)
      }

      spf = taxa.db( "spcodes.itis" )
      itaxa = itis.db( "itaxa" )
      tunits =  itis.db( "taxon.unit.types" )
   
      # reduce memory requirements: drop information below some taxonomic level
      tx_id = unique( tunits$rank_id[ which( tolower(tunits$rank_name)==itis.taxa.lowest ) ] )
      tunits = tunits[ which( tunits$rank_id <= tx_id ) , ]
			tunits = tunits[ -which(duplicated(tunits$rank_id)) ,]
			tunits = tunits[ order( tunits$rank_id) , ]

      test = NULL
      while ( is.null( test) | is.null(names(test)) ) {
        test =  itis.format( sample(nrow(spf), 1), tsn=spf$itis.tsn, itaxa=itaxa, tunits=tunits )
      }
      formatted.names = names( test )

			debug = F
			if (debug) {
				out = matrix(NA, ncol=length(test), nrow=nrow(spf) )
				for ( i in 1:nrow(spf) ) {
					o = itis.format( i, tsn=spf$itis.tsn, itaxa=itaxa, tunits=tunits )
					print (o)
					out[i,] = o
				}
			}

			res = mclapply( 1:nrow(spf), itis.format, tsn=spf$itis.tsn, itaxa=itaxa, tunits=tunits )
      res = unlist( res) 
      res = as.data.frame( matrix( res, nrow=nrow(spf), ncol=length(formatted.names), byrow=T ), stringsAsFactors=F )
      colnames(res) = tolower(formatted.names)

      spf = cbind( spf, res )

      save( spf, file=fn, compress=T )
      return ( fn )
    
    }

    if ( DS %in% c("complete", "complete.redo") ) {
		  fn = file.path( project.directory("taxonomy"), "data", "spcodes.complete.rdata") 
  	  sps = NULL
			if (DS == "complete" ) {
        if (file.exists(fn)) load(fn)
        return(sps)
      }

			sp = NULL

			tx = taxa.db("life.history")
			# tx = tx[, c("spec", "spec.clean", "itis.tsn", "rank", "rank_id", "tsn.hierarchy")]  
			# spec.clean contains manually updated spec id's
			# this routine will update these by starting with the itis tsn hierarchy
		
			spec = sort( unique( tx$spec) )

			sp.graph = network.igraph( spec=spec )
			sp.graph = network.statistics.igraph( g=sp.graph )  # add some stats about children, etc.
			
			# upack the attributes
			att = data.frame( index=1:length(V(sp.graph)) )  # dummy index to get the right number of rows
			for ( v in  list.vertex.attributes(sp.graph) ) {
				att[,v] = get.vertex.attribute(sp.graph, v)
			}
			
			# go through the list of taxa and identify updated spec.clean id's
			n0 = length(spec)
			sp = data.frame( spec=spec ) 
			sp = merge( sp, tx, by="spec", all.x=T, all.y=F )
			jj = which( !is.finite( sp$spec.clean ) )
			sp$spec.clean[jj] = sp$spec[jj] 
			
			sps = merge( sp, att[,c("id","usage","children.n","children", "sci", "parent" )], 
				by.x="itis.tsn", by.y="id", all.x=T, all.y=F) 
			
			save (sps, file=fn, compress=T)
			return (fn)
		} 
		

    if (DS %in% c( "life.history", "life.history.redo") ) {
      
      fn = file.path( project.directory("taxonomy"), "data", "spcodes.lifehistory.rdata") 
      fn.local = file.path( project.directory("taxonomy"), "data", "gstaxa_working.csv") 
      
      if (DS == "life.history" ) {
        load(fn)
        return(sps)
      }

      print( "Local files are manually maintained.")
      print( "Export to CSV if they have been updated to with '|' as a delimiter and remove last xx lines:" )
      print( fn.local )

      lifehist = read.table( fn.local, sep="|", as.is=T, strip.white=T, header=T, stringsAsFactors=F ) 
      names( lifehist ) = tolower( names( lifehist ) ) 
			lifehist$spec = as.numeric( as.character( lifehist$spec ))
      
			lifehist = lifehist[ - which( duplicated ( lifehist$spec ) ) , ]
			lifehist = lifehist[ which( is.finite( lifehist$spec ) ) , ]

      itis.taxa.lowest = tolower(itis.taxa.lowest)

      sps = taxa.db( DS="full.taxonomy", itis.taxa.lowest="species" )
      sps = merge( sps, lifehist, by="spec", all.x=T, all.y=T, sort=F) 
      
      sps$rank_id = as.numeric(  sps$rank_id  )

      sps$end = NULL  # dummy to force/check correct CVS import
      sps$subgenus = NULL
      sps$tribe = NULL

			ii = which( is.na( sps$name.scientific ) )
      sps$name.scientific[ii] = sps$name.common.worktable[ii]

			ii = which( is.na( sps$name.scientific ) )
      sps$name.scientific[ii] = sps$vernacular[ii]


			ii = which( is.na( sps$name.common ) )
			sps$name.common[ii] = sps$vernacular[ii]
      
			ii = which( is.na( sps$name.common ) )
			sps$name.common[ii] = sps$name.common.worktable[ii]

			ii = which( is.na( sps$name.scientific ) )
      sps$name.scientific[ii] = sps$name.common[ii]

			ii = which( is.na( sps$name.common ) )
      sps$name.common[ii] = sps$name.scientific[ii]

      last.check =  grep("per set", sps$name.common, ignore.case=T)
      if (length(last.check)>0) sps = sps[ -last.check , ]
     

      save( sps, file=fn, compress=T )
      return( fn )

    }

    
    if (DS %in% c( "itis.oracle", "itis.oracle.redo" ) ) {
      fn.itis = file.path( project.directory("taxonomy"), "itis.oracle.rdata" )
      if (DS=="itis.oracle" ) {  
        load( fn.itis )
        return (itis)
      }
      itis.groundfish = taxa.db( "itis.groundfish.redo" )
      itis.observer = taxa.db( "itis.observer.redo" )
      toextract = colnames( itis.observer)  # remove a few unuses vars
      itis = rbind( itis.groundfish[,toextract] , itis.observer[,toextract] )
      ii = duplicates.toremove( itis$given_spec_code )
      itis = itis[ -ii, ]
      save(itis, file=fn.itis, compress=T)
      return (itis)
    }
    
    if (DS %in% c( "itis.groundfish", "itis.groundfish.redo" ) ) {
      fn.itis = file.path( project.directory("taxonomy"), "data", "itis.groundfish.rdata" )
      if (DS=="itis.groundfish" ) {  
        load( fn.itis )
        return (itis)
      }
      require(RODBC)
      connect=odbcConnect( oracle.taxonomy.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)
      itis = sqlQuery(connect, "select * from groundfish.itis_gs_taxon")
      odbcClose(connect)
      names(itis) =  tolower( names( itis ) )
      for (i in names(itis) ) itis[,i] = as.character( itis[,i] )
      save(itis, file=fn.itis, compress=T)
      return (itis)
    }
    
    if (DS %in% c( "itis.observer", "itis.observer.redo" ) ) {
      fn.itis = file.path( project.directory("taxonomy"), "data", "itis.observer.rdata" )
      if (DS=="itis.observer" ) {  
        load( fn.itis )
        return (itis)
      }
      require(RODBC)
      connect=odbcConnect( oracle.taxonomy.server, uid=oracle.personal.user, pwd=oracle.personal.password, believeNRows=F)
      itis = sqlQuery(connect, "select * from observer.itis_isdb_species")
      odbcClose(connect)
      names(itis) =  tolower( names( itis ) )
      for (i in names(itis) ) itis[,i] = as.character( itis[,i] )
      save(itis, file=fn.itis, compress=T)
      return (itis)
    }

  }


