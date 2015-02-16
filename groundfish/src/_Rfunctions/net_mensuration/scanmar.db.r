

scanmar.db = function( DS, p, nm=NULL, id=NULL ){
  

  if (!file.exists( p$scanmar.dir )) {
   mk.Dir = readline("Directory not found, shall we create it? Yes/No (Default No) : ")
    if ( mk.Dir =="Yes" ) {
      dir.create( p$scanmar.dir, recursive=TRUE) 
      print( paste("The directory -- ",  p$scanmar.dir, " -- has been created") )
    } else {
      warning( paste("Directory: ", p$scanmar.dir, " was not found." )) 
    }
  }


  if(DS %in% c("perley", "perley.datadump" )) {
    
    # fn1= old data, fn2= new data and fn3= merged data (old and new)
    fn1= file.path(p$scanmar.dir,"scanmar.perley.rdata")
    fn2= file.path(p$scanmar.dir,"scanmarnew.perley.rdata")
    fn3= file.path(p$scanmar.dir,"scanmar.perley.merged.rdata")
   
    if(DS=="perley"){
      nm = NULL
      if (file.exists(fn3)) load(fn3)
      return(nm)
    }

    if(DS=="perley.redo"){
 
      # Package RODBC is a platform for interfacing R to database systems
      # Package includes the obdc* commands (access) and sql* functions (read, save, copy, and manipulate data between data frames)
      if (file.exists( fn1) ) {
        load(fn1)
      } else {
        require(RODBC)
        connect=odbcConnect( oracle.perley.db, uid=oracle.perley.user, pwd=oracle.perley.password, believeNRows=F)
        scanmar = sqlQuery(connect, "select * from   groundfish.perleyp_SCANMAR", as.is=T) 
        odbcClose(connect)
        save(scanmar, file=fn1, compress=T)
      }
    
      if (file.exists( fn2) ) {
        load(fn2)
      } else {
        require(RODBC)
        connect=odbcConnect( oracle.perley.db, uid=oracle.perley.user, pwd=oracle.perley.password, believeNRows=F)
        scanmarnew = sqlQuery(connect, "select * from   groundfish.perleyp_NEWSCANMAR", as.is=T) 
        odbcClose(connect)
        save(scanmarnew, file=fn2, compress=T)
      }

      nm = scanmar
      rm(scanmar)
      gc()

      names(nm)=tolower(names(nm))      #ac
      names(scanmarnew)=tolower(names(scanmarnew))      
      
      # nm is the dataset which combines the old and new data (merged)
      # some variables were missing from scanmar to faciliate the merge of scanmarnew
      nm$fspd=NA
      nm$cspd=NA        
      nm$latitude=NA
      nm$longitude=NA
      nm$depth=NA
      nm$empty=NA
      nm$time=NA

      # Correcting for data which contains NA in the time slot by identifying and deleting it
      strangedata = which(is.na(nm$logtime))
      if(length(strangedata)>0) nm=nm[-strangedata,]

      # fix some time values that have lost the zeros due to numeric conversion
      nm$logtime=gsub(":", "", nm$logtime)      
      j=nchar(nm$logtime)
      tooshort=which(j==5); if (length(tooshort)>0) nm$logtime[tooshort]=paste("0",nm$logtime[tooshort],sep="")
      tooshort=which(j==4); if (length(tooshort)>0) nm$logtime[tooshort]=paste("00",nm$logtime[tooshort],sep="")
      tooshort=which(j==3); if (length(tooshort)>0) nm$logtime[tooshort]=paste("000",nm$logtime[tooshort],sep="")
      tooshort=which(j==2); if (length(tooshort)>0) nm$logtime[tooshort]=paste("0000",nm$logtime[tooshort],sep="")
      tooshort=which(j==1); if (length(tooshort)>0) nm$logtime[tooshort]=paste("00000",nm$logtime[tooshort],sep="")
            
      nm$hours=substring(nm$logtime,1,2)
      nm$min=substring(nm$logtime,3,4)
      nm$sec=substring(nm$logtime,5,6)
      nm$time = paste(nm$hours, nm$min, nm$sec, sep=":")
      

      # creating a matrix (nm2) with nm and scanmarnew
      nm2=matrix(NA,ncol=ncol(nm),nrow=nrow(scanmarnew))
      nm2= as.data.frame(nm2)
      names(nm2)=names(nm)
      
      # making the columns names of nm2 equal to those of scanmarnew
      o =names(scanmarnew)
      for(n in o){
        nm2[,n]=scanmarnew[,n]
      }
      
      # Combining rows of nm and nm2 to create the data frame nm
      nm=rbind(nm,nm2)      
      rm(scanmarnew, nm2)
      gc()
     
      #This step is creating variables by pasting existing together
      #It is also changing character values to numeric
      nm$uniqueid=paste(nm$mission,nm$setno,sep="_")
      nm$ltspeed=as.numeric(nm$ltspeed)
      nm$ctspeed=as.numeric(nm$ctspeed)
      nm$doorspread=as.numeric(nm$doorspread)
      nm$wingspread=as.numeric(nm$wingspread)
      nm$clearance=as.numeric(nm$clearance)
      nm$opening=as.numeric(nm$opening)
      nm$depth=as.numeric(nm$depth)
      nm$latitude=as.numeric(nm$latitude)
      nm$longitude=as.numeric(nm$longitude)
      nm$year.mission= as.numeric(substring(nm$mission,4,7))
      nm$fspd=as.numeric(nm$fspd)
      nm$cspd= as.numeric(nm$cspd)
      
      
      # merge groundfish  timestamps and ensure that net mensuration timestamps are correct
      nm$id=paste(nm$mission, nm$setno, sep=".")
      ii = which( nm$longitude > 0 )
      if (length(ii) > 0 ) nm$longitude[ii] = - nm$longitude[ii] 
      
      # load groundfish inf table which has timestamps of start/stop times and locations
      gsinf = groundfish.db( DS="gsinf" )
      gsinfvars=c("id", "sdate", "settype" )
      
      # merge 
      nm = merge( nm, gsinf[,gsinfvars], by="id", all.x=TRUE, all.y=FALSE)
      
      nm$day = day( nm$sdate )
      nm$mon = month( nm$sdate )
      nm$year = year( nm$sdate )
      nm$date = paste(nm$year, nm$mon, nm$day, sep="-")
    
      i = which(!is.finite(nm$day))
      if (length(i)>0) nm = nm[ -i, ]

      i = which( is.na( nm$time))
      if (length(i)>0) nm = nm[ -i, ]
 
      nm$tstamp= paste( nm$date, nm$time )
      
      tzone = "America/Halifax"  ## need to verify if this is correct
  
      #lubridate function 
      nm$timestamp = ymd_hms(nm$tstamp)
      tz( nm$timestamp )=tzone

      keep=c("id", "vesel", "ltspeed", "ctspeed", "wingspread", "doorspread", "clearance",
             "opening", "fspd", "cspd", "latitude", "longitude", "depth", "settype", "timestamp"
             )
      nm=nm[,keep]

      # fix sets that cross midnight and list
      # some sets cross midnight and require days to be adjusted
      nm$timestamp = timestamp.fix (nm$timestamp, threshold.hrs=2 )
      
      save(nm, file=fn3,compress=TRUE)
    }
  }
 
  
  if(DS %in% c("basedata", "basedata.redo"))  {
 
    print( "## TODO :: make this operate upon 1 year at a time similar to snowcrab approach ## ")
   
    tzone = "America/Halifax"  ## need to verify if this is correct
    basedata=NULL
    
    fn=file.path( p$scanmar.dir, paste( "scanmar", "basedata","rdata", sep="." ))
    if(DS == "basedata"){
      if (file.exists(fn)) load(fn)
      return(basedata)
    }
    
    rawdata.dir = file.path( p$scanmar.dir, "datalogs" )
    filelist = list.files(path=rawdata.dir, pattern="set.log", full.names=T, recursive=TRUE, ignore.case=TRUE)
    unneeded = grep ("copy", filelist, ignore.case=TRUE)
    if (length(unneeded>0)) filelist = filelist[-unneeded]
    for ( fl in filelist ) {
      print(fl)
      j = load.scanmar.rawdata( fl, tzone=tzone )  # variable naming conventions in the past
      if (is.null(j)) next()
      basedata = rbind( basedata, j)
    }
    
    tz(basedata$timestamp) = tzone
    save(basedata, file=fn, compress= TRUE)
    
    return(fn)
  }



  # -------------------------------------


  if (DS %in% c("metadata", "metadata.redo"))  {
    
    # match sets with scanmar data using time and gpstrack / location information
    fn  = file.path(p$scanmar.dir, paste("scanmar.meta", "rdata", sep= "."))
    meta= NULL  
  
    if (DS == "metadata") {
      if (file.exists(fn)) load(fn)
      return(meta)
    }

      
    gf=groundfish.db(DS="gsinf")
    
    
    # Incorporation of newer data, combining timestamp
    pp=scanmar.db( DS="basedata", p=p ) 
    pp$lon=pp$longitude
    pp$lat=pp$latitude
    
    meta=data.frame(uniqueid=unique(pp$id), stringsAsFactors=FALSE )
    meta$sdate=NA
    meta$id=NA
    meta$bottom_temperature=NA
    meta$slon=NA
    meta$slat=NA
    meta$elon=NA
    meta$elat=NA
    meta$strat=NA
    meta$time.end=NA
    meta$min.distance = NA
   
    for(i in 1:nrow(meta)){
      k = meta$uniqueid[i]
      print(k)
      
      j = which(pp$id == k)
      if(length(j)>0) {
        ppc=pp[j,]
        
        m = which.min(ppc$timestamp)
        meta$sdate[i] = as.character(ppc$timestamp[m])
        dif = as.duration(ymd_hms(meta$sdate[i]) - gf$sdate)
        u = which(abs(dif)< dhours  (9) )
        
        if(length(u)> 1) {
          gfs=gf[u,]
          gfs$min.distance.test=NA
          
          for(v in 1:nrow (gfs)){
            distance.test = geodist(ppc[,c("lon","lat")], gfs[v,c("lon","lat")], method="great.circle")
            gfs$min.distance.test[v] = min(distance.test, na.rm=TRUE)
          }
          
          w = which.min(gfs$min.distance.test)
          if(gfs$min.distance.test[w]< 1 ){
            meta$id[i]=gfs$id[w]  # exact match with very high confidence
            meta$min.distance[i] = gfs$min.distance.test[w]
          } 
        }
      }
    }
    
    # fnn2 = "tmp.meta.rdata"
    # save( meta, file=fnn2)
    # load (fnn2)
    
    # Check for duplicates as some are data errors .. needed to be checked manually and raw data files altered
    # others are due to bad tows being redone ... so invoke a distance based rule as the correct one in gsinf (good tows only are recorded)
    dupids = unique( meta$id[ which( duplicated( meta$id, incomparables=NA) ) ] )
    for ( dups in dupids ) {
      uu = which(meta$id %in% dups)
      good = uu[ which.min( meta$min.distance[uu] ) ]
      notsogood = setdiff( uu, good )    
      meta$id[notsogood] = NA       
    }
    
    # redo the distance-based match to catch any that did not due to being duplicates above
    # does not seem to do much but kept for posterity
    
    unmatched = which( is.na(meta$id ) )
    if (length (unmatched) > 0) {
      for(i in unmatched ){
        
        k = meta$uniqueid[i]
        print(k)
        
        j = which(pp$id == k)
        if(length(j)>0) {
          ppc=pp[j,]
          m = which.min(ppc$timestamp)
          meta$sdate[i] = as.character(ppc$timestamp[m])
          dif = as.duration(ymd_hms(meta$sdate[i]) - gf$sdate)
          u = which(abs(dif)< dhours  (9)) 
          
          ## the next two lines are where things are a little different from above
          ## the catch all as yet unmatched id's only for further processing
          current.meta.ids = unique( sort( meta$id) )
          u = u[ which( ! (gf$id[u] %in% current.meta.ids ) )]
          
          if(length(u)> 1) {
            gfs=gf[u,]
            gfs$min.distance.test=NA
            
            for(v in 1:nrow (gfs)){
              distance.test = geodist(ppc[,c("lon","lat")], gfs[v,c("lon","lat")], method="great.circle")
              gfs$min.distance.test[v] = min(distance.test, na.rm=TRUE)
            }
            
            w = which.min(gfs$min.distance.test)
            if(gfs$min.distance.test[w]< 1 ){
              meta$id[i]=gfs$id[w]  # exact match with very high confidence
              meta$min.distance[i] = gfs$min.distance.test[w]
            } 
          }
        }
      }
    }
    
    
    ## now do a more fuzzy match based upon time stamps as there are no matches based upon distance alone
    
    nomatches = which( is.na( meta$id) )
    if (length(nomatches) > 1) {
      for(i in nomatches){
        k = meta$uniqueid[i]
        print(k)
        j = which(pp$id == k)
        if(length(j)>0) {
          ppc=pp[j,]
          m = which.min(ppc$timestamp)
          meta$sdate[i] = as.character(ppc$timestamp[m])
          dif = as.duration(ymd_hms(meta$sdate[i]) - gf$sdate)
          
          u = which( abs(dif)< dhours  (1) )
          if (length(u) == 1 ) { 
            current.meta.ids = unique( sort( meta$id) )
            u = u[ which( ! (gf$id[u] %in% current.meta.ids ) )]
            if (length(u) == 1 )   meta$id[i]= gfs$id[u]
          }          
        }
      }
    }    
    save(meta, file= fn, compress= TRUE)

  }

  # -------------------------------------
 
 

  if(DS %in% c("merge.historical.scanmar", "merge.historical.scanmar.redo" )) {
    
    fn= file.path(p$scanmar.dir,"all.historical.data.rdata")
    master=NULL
    if(DS=="merge.historical.scanmar"){
      if (file.exists(fn)) load(fn)
      return(master)
    }
    
    pp = scanmar.db( DS="basedata", p=p ) 
    pp$uniqueid = pp$id
    pp$id = NULL
    
    nm = scanmar.db( DS="perley", p=p ) 
    nm$netmensurationfilename = "Perley Oracle instance"
    w = which(!is.finite(nm$cspd))
    nm$ctspeed[w]=nm$cspd[w]
    v = which(!is.finite(nm$fspd))
    nm$ltspeed[v]=nm$fspd[v]
    v.to.drop = c("vesel", "empty", "logtime", "cspd", "fspd", "settype", "dist" )
    for ( v in v.to.drop) nm[,v] = NULL
    nm$gyro=NA  
    nm$edate = NULL
    
    # here we will add the more modern data series and merge with perley
    meta =  scanmar.db( DS="metadata", p=p )
   
    pp = merge(pp, meta, by="uniqueid", all.x=TRUE, all.y=FALSE)
    
    pp$netmensurationfilename = pp$uniqueid 
    pp$uniqueid=NULL
    pp$ctspeed=NA
    
    # setdiff(names(nm), names(pp))
    pp=pp[,names(nm)]
    
    # this is where we add the marport data/2010-2011 data
    master=rbind(nm, pp)
    
    master$date = substring(as.character(master$timestamp), 1,10)
    gooddata = which( !is.na( master$id))
    
    
    ids = strsplit( master$id[gooddata], "[.]" )
    
    mission.trip = unlist( lapply( ids, function(x){x[[1]]} ) )
    setno = unlist( lapply( ids, function(x){x[[2]]} ) )
    
    master$set = NA
    master$set[gooddata] = as.numeric( setno )
    
    master$trip = NA
    master$trip[gooddata] = substring( mission.trip, 8,10 )
    master$trip = as.numeric(master$trip)
    master$year=year(master$timestamp)  
    
    save(master, file=fn, compress= TRUE)
    
  }


  if ( DS %in% c("sanity.checks", "sanity.checks.redo") ) {
   # Step to filter data  
   
   fn = file.path( p$scanmar.dir, "scanmar.sanity.checked.rdata")
   if(DS=="sanity.checks") {
     nm = NULL
     if (file.exists(fn)) load(fn)
     return(nm)
   }

   nm = scanmar.db( DS="merge.historical.scanmar", p=p ) 
   
   # remove sets where american trawls were used for comparative surveys
   nm = filter.nets("remove.trawls.with.US.nets", nm)
   # empty variable is not needed (crossed channel with doorspread), also values present look erroneous in NED2005001 1
   i = which( nm$id=="NED2005001.1" )
   nm$doorspread[i] = NA
   nm$wingspread[i] = NA
   nm$clearance[i] = NA
   nm$opening[i] = NA
   nm$ltspeed[i] = NA
   nm$ctspeed[i] = NA
   
   # coarse level gating   
   nm$doorspread = filter.nets("doorspread.range", nm$doorspread)
   nm$wingspread = filter.nets("wingspread.range", nm$wingspread)
   nm$clearance = filter.nets("clearance.range", nm$clearance)
   nm$opening = filter.nets("opening.range", nm$opening)
   nm$depth = filter.nets("depth.range", nm$depth)
#   nm$door.and.wing.reliable = filter.nets( "door.wing", nm )    # flag to ID data that are bivariately stable .. errors still likely present
 
   save( nm, file=fn, compress=TRUE)
   return (fn )
  }


  if (DS %in% c("bottom.contact", "bottom.contact.redo", "bottom.contact.id" )) {
    scanmar.bc.dir =  file.path(p$scanmar.dir, "bottom.contact" )
    dir.create( scanmar.bc.dir, recursive=TRUE, showWarnings=FALSE ) 
    dir.create (file.path( scanmar.bc.dir, "results"), recursive=TRUE, showWarnings=FALSE )
    dir.create (file.path( scanmar.bc.dir, "figures"), recursive=TRUE, showWarnings=FALSE )

    fn= file.path(p$scanmar.dir,"gsinf.bottom.contact.rdata" )
    gsinf=NULL
    if(DS=="bottom.contact"){
      if (file.exists(fn)) load(fn)
      return(gsinf)
    }

    if(DS=="bottom.contact.id"){
      fn.bc = file.path( scanmar.bc.dir, "results", paste( "bc", id, "rdata", sep=".") )
      bc = NULL
      if (file.exists(fn.bc)) load(fn.bc)
      return(bc)
    }
    
    gsinf = groundfish.db( DS="gsinf" )
    gsinf$bottom_duration = NA
    gsinf$bc0.datetime = as.POSIXct(NA)
    gsinf$bc1.datetime = as.POSIXct(NA)
    gsinf$bc0.sd = NA
    gsinf$bc1.sd = NA
    gsinf$bc0.n = NA
    gsinf$bc1.n = NA
    
    master = scanmar.db( DS="sanity.checks", p=p )
    master = master[which(is.finite(master$depth)) ,  ]
    
    if ( !is.null( p$override.missions)){
      p$user.interaction = TRUE
      master = master[ which(master$id %in% p$override.missions ), ]
    }
    

    fn.current = file.path( p$scanmar.dir, "bottom.contact.tmp.current" )
    fn.badlist = file.path( p$scanmar.dir, "bottom.contact.badlist" )
    fn.gsinf = file.path( p$scanmar.dir, "bottom.contact.tmp.gsinf" )

    if ( file.exists (fn.current) ) file.remove( fn.current )
    if ( file.exists (fn.badlist) ) file.remove( fn.badlist )
    if ( file.exists (fn.gsinf) ) file.remove( fn.gsinf )

    badlist = skip = cur = NULL
    
    uid = sort( unique( master$id)) 


    ### if rerun necessary .. start from here until R-inla behaves more gracefully with faults

    if ( file.exists (fn.current) ) {
      # if there is something in the current id from a previous run, this indicates that this is likely a re-start
      # reload saved data and skip ahead to the next id
        cur = scan( fn.current, what="character", quiet=TRUE )
        if ( length(cur) > 0 ) {
          skip = which( uid==cur ) + 1
          uid = uid[ skip: length(uid) ]
          # load( fn.gsinf)  # as it is a restart ... load in the saved version instead of the initial version
        }
    }


    for ( id in uid) {
      
      print( id)

      # in sufficient data for these: 
      if ( id %in% c("NED2013028.106", "NED2013028.147", "NED2013028.188", "NED2013028.83" ) ) {
        # these are just flat-lines .. no reliable data
        next()
      }

      if ( file.exists (fn.current) ) {
        # if there is something in the current id from a previous run, this indicates that this is likely a re-start
        # add it to the list of "bad.list" and skip over for manual analysis
        cur = scan( fn.current, what="character", quiet=TRUE )
        if ( length(cur) > 0 ) {
          bad.list = NULL
          if (file.exists(fn.badlist) ) {
            bad.list = scan( fn.badlist, what="character", quiet=TRUE )
          }
          cat( unique( c(bad.list, cur)), file=fn.badlist )
        }
      }
      
      if ( file.exists (fn.badlist) ) {
        bad.list = scan( fn.badlist, what="character", quiet=TRUE )
        if ( id %in% bad.list ) next()
      }
      
      cat( id, file = fn.current )
      
      # id = "TEL2004529.21"

      ii = which( master$id==id )  # rows of master with scanmar/marport data
      if ( length( which( is.finite(master[ii, "depth"]))) < 30 ) next() ## this will also add to the bad.list .. when insufficient data  
      gii = which( gsinf$id==id )  # row of matching gsinf with tow info
      if (length(gii) != 1) next()  # no match in gsinf  ## this will also add to the bad.list .. when insufficient data
     
      mm = master[ which(master$id==id) , c("depth", "timestamp") ]

      # define time gate -20 from t0 and 50 min from t0, assuming ~ 30 min tow
      time.gate = list( t0=gsinf$sdate[gii] - dminutes(20), t1=gsinf$sdate[gii] + dminutes(50) )
      
      # x=mm; depthproportion=0.6; tdif.min=15; tdif.max=45; eps.depth=4; sd.multiplier=5; depth.min=10; depth.range=c(-50, 50); smoothing = 0.9; filter.quants=c(0.025, 0.975); plot.data=TRUE
      
      # defaults appropriate for more modern scanmar data have > 3500 pings
      # see:  tapply( master$year,  list(master$id, master$year), length )
      sd.multiplier = 5
      depthproportion = 0.8 # multiplier to Zmax, Zmedian estimate ... bigger the number more get filtered out
      smoothing = 0.95
      filter.quants=c(0.05, 0.95)
      eps.depth = 0.5
      depth.range = c(-60, 60)
      
      if (nrow(mm) < 3500 ) {
        # mostly 2004 to 2008
        sd.multiplier = 5
        depthproportion = 0.8
        smoothing = 0.75
        filter.quants=c(0.1, 0.9)
        eps.depth = 1
        depth.range = c(-60, 40)
       } 
  
      if (nrow(mm) < 1200 ) {
        # mostly 2004 to 2008
        sd.multiplier = 4
        depthproportion = 0.5
        smoothing = 0.5
        filter.quants=c(0.025, 0.975)
        eps.depth = 1
        depth.range = c(-60, 40)
      } 
     
      if (nrow(mm) < 200 ) {
        # mostly 2004 to 2008 ... truncated already 
       sd.multiplier = 5
        depthproportion = 0.1
        smoothing = 0.4
        filter.quants=c(0.05, 0.95) # keep as much data as possible
        eps.depth = 1   # ... pre-gated  with not much room to model
        depth.range = c(-60, 30)
      } 
   
      if (nrow(mm) < 100 ) {
        # mostly 2004 to 2008 ... truncated already 
        sd.multiplier = 5
        depthproportion = 0.1
        smoothing = 0.4
        filter.quants=c(0.01, 0.99) # keep as much data as possible
        eps.depth = 1   # ... pre-gated  with not much room to model
        depth.range = c(-60, 30)
      } 

      if (id=="NED2013028.172") {
        depth.range = c(-70, 70) 
      }
   
      bc = NULL # 
      bc = try( bottom.contact(id, mm, depthproportion=depthproportion, tdif.min=15, tdif.max=45, eps.depth=eps.depth, 
                 sd.multiplier=sd.multiplier, depth.min=10, depth.range=depth.range, smoothing=smoothing, filter.quants=filter.quants, 
                 plot.data=TRUE, outdir=file.path(scanmar.bc.dir, "figures"), time.gate=time.gate ), 
          silent=TRUE)


      if ( ! is.null(bc) && ( ! ( "try-error" %in% class(bc) ) ) ) { 
        gsinf$bc0.datetime[gii] = bc$bottom0 
        gsinf$bc1.datetime[gii] = bc$bottom1
        gsinf$bottom_duration[gii] = bc$bottom.diff
        gsinf$bc0.sd[gii] = bc$bottom0.sd
        gsinf$bc1.sd[gii] = bc$bottom1.sd
        gsinf$bc0.n[gii] =  bc$bottom0.n
        gsinf$bc1.n[gii] =  bc$bottom1.n
        if ( !is.finite( gsinf$bottom_depth[gii]))  gsinf$bottom_depth[gii] = bc$depth.mean
        save (gsinf, file=fn.gsinf)  # temporary save in case of a restart in required for the next id
        fn.bc = file.path( scanmar.bc.dir, "results", paste( "bc", id, "rdata", sep=".") )  
        save ( bc, file=fn.bc, compress=TRUE )
      }
        
      # if only the loop completes without error, reset the flag for current id on filesystem
      cat("", file=fn.current )
    }


    ## END of re-run area ... 

    if (!is.null( p$override.missions)) {
      fn = paste( fn, "manually.determined.rdata", sep="")
      print( "Saving to an alternate location as this is being manually handled ... merge this by hand:" )
      print( fn)
    }
    
    save(gsinf, file=fn, compress= TRUE)
    
    print( "Use, override.mission=c(...) as a flag and redo .. manually ) for the following:" )
    print( "Troublesome id's have been stored in file:")
    print( fn.badlist )
    print(  scan( fn.badlist, what="character", quiet=TRUE ) )

    if (file.exists(fn.current)) file.remove( fn.current )
    if (file.exists(fn.gsinf)) file.remove( fn.gsinf ) 
    return(fn)
  }

   

  # -----------------------------------


  if (DS %in% c("sweptarea", "sweptarea.redo" )) {
     
    fn = file.path( p$scanmar.dir, "gsinf.sweptarea.rdata")
    gs = NULL
    if( DS=="sweptarea" ){
      if (file.exists(fn)) load(fn)
      return(gs)
    }
 
    nm = scanmar.db( DS="sanity.checks", p=p )
    nm = nm[which(is.finite( nm$depth)) ,  ]
   
    gs = scanmar.db( DS="bottom.contact", p=p )
    gs$dist = NULL  # dummy values .. remove to avoid confusion 
    
    # get variable names and sequence of var's
    gstest = estimate.swept.area( getnames=TRUE )
    newvars = setdiff( gstest, names( gs) )
    for (vn in newvars) gs[,vn] = NA
    gs = gs[, names(gstest) ] # reorder

    if(FALSE) {
      # debugging 
      id="TEM2008775.22"
      id="NED2010001.59"
      ii = which( nm$id==id ) 
      gii = which( gs$id==id ) 
      gs = gs[gii,]
      x = nm[ii,]
    }
 
    nreq = 30
    sd.max = 30  # in seconds 
    uid = sort( unique( nm$id)) 
    
    for ( id in uid) {
      print( id)
      jj = NULL
      jj = which( nm$id==id )  # rows of nm with scanmar/marport data
      tk = which( nm$timestamp[ii] >= gs$bc0.datetime[gsi] & nm$timestamp[ii] <= gs$bc1.datetime[gsi] )
      if (length(tk) < nreq ) next()
      ii = jj[tk]
      if ( length( which( is.finite(nm[ii, "depth"]))) < nreq ) next()  
      gii = which( gs$id==id )  # row of matching gsinf with tow info

      if ( all (is.finite( c( gs$bc0.sd[gii], gs$bc1.sd[gii] ) ))) {
      if ( gs$bc0.sd[gii] <= sd.max & gs$bc1.sd[gii] <= sd.max )  {  

        # SD of start and end times must have a convengent solution which is considered to be stable when SD < 30 seconds
        sa = estimate.swept.area( gsi = gs[gii,],  x= nm[ii,] )
        gs$sa[gii] = sa$surfacearea
        # gs$ ...

      }}
    }
    save(gs, file=fn, compress= TRUE)
  }

} 


