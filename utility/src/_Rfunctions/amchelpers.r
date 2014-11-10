#custom functions to read in
#source('C:\\Users\\CookA\\Desktop\\Scripts\\amc helpers.R')

#MMM - Sept 18, 2014 - is this simply a repeat of -ecomodSetup\loadfunctions()?  
#If so, is it necessary?		
loadfun <- function(path) {
a <- dir(file.path(path,'src'))
for(i in 1:length(a)) {
source(file.path(path,'src',a[i]))
}
}
## #############################################################################
## #############################################################################
## #Notes - Mike McMahon, Sept 2014
## #the following functions existed within this file, but have been moved into 
## #their own standalone file within the utility folder (or a subfolder therein)
## #Once a function was either turned into a discrete r file, it was moved to 
## this section, and commented out.  This section should likely also be deleted 
##  pending AMC's approval
## #############################################################################
## #############################################################################
## #MMM - Sept 18, 2014 - added cX to  _Rfunctions\interoperability
## 
## #write table to paste into excel
## cX <- function(X,row.names=F) {
## 	write.table(X,'clipboard-512',sep="\t",row.names=row.names)
## }
## #############################################################################
## #MMM - Sept 18, 2014 - added rX to  _Rfunctions\interoperability
## 
## #read table to copied from excel
## rX <- function(header=T) {
## 	read.table('clipboard-512',sep="\t",header=header)
## }
## #############################################################################
## #MMM - Sept 18, 2014 - added getCols.r to _Rfunctions\colours 
## 
## #get color vector for plot
## getCols <- function(n){
## 	 N <- 6
## 	 
## 	 X <- seq(N^2)-0.5
## 	 Y <- seq(N)-0.5
## 	 Z <- matrix(0, nrow=length(X), ncol=length(Y))
##  
## 	 LEV <- seq(0,1,,N) 
## 	 R <- rep(LEV, each=N^2)
## 	 G <- rep(rep(LEV, each=N), N)
## 	 B <- rep(LEV, N^2)
## 	 
## 	 x11(width=6, height=6)
## 	 layout(matrix(1:2, nrow=2, ncol=1), widths=c(6), heights=c(1.5,4.5))
## 	 op <- par(mar=c(1,3,2,1))
## 	 
## 	 image(X,Y,Z, col=NA, xlab="", ylab="", xaxt="n", yaxt="n")
## 	 for(i in seq(Z)){
## 		xs <- c(((i-1) %% N^2), ((i-1) %% N^2), ((i-1) %% N^2) + 1, ((i-1) %% N^2) + 1)
## 		ys <- c(((i-1) %/% N^2), ((i-1) %/% N^2)+1, ((i-1) %/% N^2) + 1, ((i-1) %/% N^2))
## 		polygon(xs, ys, col=rgb(R[i], G[i], B[i]), border=NA)
## 	 }
## 	 mtext(paste("Click on", n, "colors [please]"), side=3, line=0.5)
## 	 box()
##  
## 	COLS <- NA*seq(n)
## 	for(i in seq(n)){
## 		coord <- locator(1)
## 		red <- coord$y / N
## 		green <- coord$x / N^2
## 		blue <- (coord$x %% N) / N
## 		#pos <- (round(coord$y-1) * N^2) + round(coord$x)
## 		COLS[i] <- rgb(red, green, blue)
## 	}
##  
## 	par(mar=c(1,3,0,1))
## 	pal <- colorRampPalette(c("black", "white"))
## 	image(x=1:100, y=seq(n), z=matrix(rep(1:100,n), nrow=100, ncol=n), col=pal(100), xlab="", ylab="", xaxt="n", yaxt="n")
## 	box()
## 	for(i in seq(n)){
## 		lines(x=c(1,100), y=c(i,i), col=COLS[i], lwd=4)
## 	}
## 	axis(2, at=seq(n))
## 
## 	par(op)
## 
## 	COLS
## }
## #usage getCols(5)
## #############################################################################
## #MMM - Sept 18, 2014 - added getPackage.r to _Rfunctions\packages 
## 
## #load in package if not in lib need to put quotes around name
## getPackage <- function(pkg){
## 	if(!require(pkg, character.only=TRUE)){
## 		install.packages(pkg, dependencies=TRUE)
##     }  
## 	require(pkg, character.only=TRUE,quietly=T)
## }
## #############################################################################
## #MMM - Sept 18, 2014 - added convert.dd.dddd.r to _Rfunctions\coordinates 
## 
## ###-- convert 2 decdegrees      
## convert.dd.dddd<-function(ddmm.mm){
## 	
## 	dat<-data.frame(ddmm.mm,dd.dddd=NA)
## 	
## 	ddmmss<-dat$ddmm.mm[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)>9000]
## 	ddmm.ss<-ddmmss/100
## 	ddmm<-trunc(ddmm.ss)
## 	ss<-(ddmm.ss-ddmm)*100
## 	dd.mm<-ddmm/100
## 	dd<-trunc(dd.mm)
## 	mm<-(dd.mm-dd)*100
## 	dat$dd.dddd[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)>9000]<-dd+mm/60+ss/3600
## 
## 	dd.mmmm<-dat$ddmm.mm[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)>90&abs(dat$ddmm.mm)<9000]/100
## 	dd<-trunc(dd.mmmm)
## 	mm.mm<-(dd.mmmm-dd)*100
## 	dat$dd.dddd[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)>90&abs(dat$ddmm.mm)<9000]<-dd+mm.mm/60
## 
## 	dat$dd.dddd[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)<90]<-dat$ddmm.mm[!is.na(dat$ddmm.mm)&abs(dat$ddmm.mm)<90]
## 	
## 	return(dat$dd.dddd)
## 	
## }
## #############################################################################
## #MMM - Sept 18, 2014 - added dstamp.r  to _Rfunctions
## 
## ###-function to add a datestamp to the bottom right corner of a figure
## dstamp<- function (txt, pwd = FALSE, time. = TRUE) {
##     stamp <- function(string = Sys.time(), print = TRUE, plot = TRUE) {
## 		opar <- par(yaxt = "s", xaxt = "s", xpd = NA)
## 		on.exit(par(opar))
## 		plt <- par("plt")
## 		usr <- par("usr")
## 		xcoord <- usr[2] + (usr[2] - usr[1])/(plt[2] - plt[1]) * (1 - plt[2]) - 0.6 * strwidth("m")
## 		ycoord <- usr[3] - diff(usr[3:4])/diff(plt[3:4]) * (plt[3]) + 0.6 * strheight("m")
## 		if (par("xlog")) 
## 			xcoord <- 10^(xcoord)
## 		if (par("ylog")) 
## 			ycoord <- 10^(ycoord)
## 		text(xcoord, ycoord, string, adj = 1)
## 		invisible(string)
##     }
##     date.txt <- if (time.) 
##         format(Sys.time())
##     else format(Sys.time(), "%Y-%m-%d")
##     if (pwd) 
##         date.txt <- paste(getwd(), date.txt)
##     oldpar <- par(mfrow = c(1, 1), cex = 0.5)
##     on.exit(par(oldpar))
##     if (!missing(txt)) 
##         date.txt <- paste(txt, "   ", date.txt, sep = "")
##     stamp(string = date.txt, print = FALSE, plot = TRUE)
##     invisible()
## }
## #############################################################################
## #MMM - Sept 18, 2014 - modified existing capwords.r to have the sentence 
## functionality (ie these functions were different, but now they're the same)	
## 
## ### - function to capitalize words
## capwords <- function(s, strict = FALSE, sentence=T) {
## 	cap <- function(s) paste(toupper(substring(s,1,1)),
## 	  {s <- substring(s,2); if(strict) tolower(s) else s},
## 			   sep = "", collapse = " " )
## 		if(sentence) {
## 			sapply(s, cap, USE.NAMES = !is.null(names(s)))
## 		} else {
## 			sapply(strsplit(s, split = " "), cap, USE.NAMES = !is.null(names(s)))
## 		}
## 	}
## #############################################################################
## #MMM - Sept 18, 2014 - added toNums.r  to _Rfunctions
## 
## toNums<-function(x,cols,numerics=T) {
## 	for(i in 1:length(cols)) {
## 		if(is.factor(x[,cols[i]])) {
## 			if(numerics==F){
## 				x[,cols[i]]<-as.character(levels(x[,cols[i]])[x[,cols[i]]])
## 			} else {
## 				x[,cols[i]]<-as.numeric(levels(x[,cols[i]])[x[,cols[i]]])
## 			}
## 		} else {
## 			x[,cols[i]]<-as.numeric(x[,cols[i]])
## 		}
## 	}
## 	return(x)
## }
## #############################################################################
## #MMM 2014 added FB2C.r to _Rfunctions\fishingmortality
## 
## #catch given Fishing mortality and Biomass
## #useful for  projections
## FB2C <- function(F,B) {
## 	C = B*(exp(F)-1)*exp(-F)
## 	return(C)
## }
## #############################################################################
## #MMM 2014 added U2F.r to _Rfunctions\fishingmortality
## 
## #exploitation rate to fishing mortality
## U2F <- function(U){
## 	return(-log(1-U))
## }
## #############################################################################
## #MMM - Sept 18, 2014 added recode.r to _Rfunctions\datacleaning
## 
## #recode a column of variables easily
## #useage dat$species <- recode(dat$species,  "10=2; 60=6; 15=3;400=7;11=5;16=8;
## #								14=10;200=11; 220=12;12=13;50=14;40=4") 
## #useage recode(out$ID,"'ESS'='4VW';'WSS'='4X'")
## recode <- function (var, recodes) {    
##     recodes <- gsub("\n|\t", " ", recodes)
##     recode.list <- rev(strsplit(recodes, ";")[[1]])
##     is.fac <- is.factor(var)
##     as.factor.result <- is.fac
##     if (is.fac) var <- as.character(var)
##     result <- var
##     if (is.numeric(var)) {
##         lo <- min(var, na.rm = TRUE)
##         hi <- max(var, na.rm = TRUE)
##     }
##     for (term in recode.list) {
##         if (0 < length(grep(":", term))) {
##             range <- strsplit(strsplit(term, "=")[[1]][1], ":")
##             low <- eval(parse(text = range[[1]][1]))
##             high <- eval(parse(text = range[[1]][2]))
##             target <- eval(parse(text = strsplit(term, "=")[[1]][2]))
##             result[(var >= low) & (var <= high)] <- target
##         }
##         else if (0 < length(grep("^else=", squeezeBlanks(term)))) {
##             target <- eval(parse(text = strsplit(term, "=")[[1]][2]))
##             result[1:length(var)] <- target
##         }
##         else {
##             set <- eval(parse(text = strsplit(term, "=")[[1]][1]))
##             target <- eval(parse(text = strsplit(term, "=")[[1]][2]))
##             for (val in set) {
##                 if (is.na(val)) 
##                   result[is.na(var)] <- target
##                 else result[var == val] <- target
##             }
##         }
##     }
##         result.valid <- na.omit(result)
##         opt <- options(warn = -1)
##         result.valid <- as.numeric(result.valid)
##         options(opt)
##         if (!any(is.na(result.valid)))  result <- as.numeric(result)
##     
##     result
## }
## #############################################################################
## #MMM - Sept 18, 2014 added sort.list.amc.r to _Rfunctions\datacleaning
## 
## #sorts all elements in a list based on the column r
## sort.list.amc<-function(list1,r,inc=T) { 
## 	#r=column number for sort
## 	a<-length(list1)
## 	b<-list1
## 	for(i in 1:a) {
## 	ee<-list1[[i]]
## 	if(inc) {b[[i]]<-ee[order(ee[,r]),]}
## 	else {b[[i]]<-ee[rev(order(ee[,r])),]}
## 	}
## 	return(b)
## }
## #############################################################################
## #MMM - Sept 18, 2014 added squeezeBlanks.r to _Rfunctions\datacleaning
## 
## squeezeBlanks <- function (text) 
## {
##     gsub(" *", "", text)
## }
## #############################################################################
## #MMM - Sept 18, 2014 added completeFun.r to _Rfunctions\datacleaning
## 
## #remove rows where specific columns have NA
## completeFun <- function(data, desiredCols) {
## 	#usage completeFun(dd,'y')
##   completeVec <- complete.cases(data[, desiredCols])
##   return(data[completeVec, ])
## }
## #############################################################################
## #MMM - Sept 18, 2014 added fillNaDf2.r to _Rfunctions\datacleaning
## 
## #function to fill in nas with vaules from a table matching one or several 
## columns
## fillNaDf2 <- function(naDf, fillDf, mergeCols, fillCols) {
## 	fillB <- do.call(paste, c(fillDf[, mergeCols, drop = FALSE], sep="\r"))
## 	naB <- do.call(paste, c(naDf[, mergeCols, drop = FALSE], sep="\r"))
## 	m <- match(naB, fillB)
## 	for(col in fillCols) {
## 		fix <- which(is.na(naDf[,col]))
## 		naDf[fix, col] <- fillDf[m[fix],col]
## 	}
## 	naDf
## }
## #############################################################################
## #MMM - Sept 18, 2014 added fm.m.r to _Rfunctions\
## 
## #fathoms to m
## fm.m<-function(x) {
## 	m <- x*(6*12*2.54)/100
## 	return(m)
## }
## #############################################################################
## #MMM - Sept 18, 2014 added rm.to.list.r to _Rfunctions\datacleaning
## 
## #removes elements from list that contain no information
## rm.from.list<-function(list1) {
## 	a<-dim.list(list1)
## 	if(any(a[,1]==0)) {
## 		list1<-list1[-which(a[,1]==0)]
## 	}
## 	return(list1)
## }
## #############################################################################
## #MMM - Sept 18, 2014 added list.names.to.columns.r to _Rfunctions\datacleaning
## 
## list.names.to.columns<-function(data) {
## 	for(i in 1:length(data)) {
## 		if( !is.null(data[[i]])) {
## 			data[[i]][length(data[[i]])+1]<-names(data[i])
## 			if(grepl('\\.',length(data[[i]])+1)) {
## 				a<-unlist(strsplit(data[[i]][length(data[[i]])],split="\\."))
## 				data[[i]]<-as.vector(c(data[[i]],(a)))
## 			}
## 		}
## 	}
## 	data<-do.call(rbind,data)
## 	return(data)
## }
## #############################################################################		
## #MMM - Sept 18, 2014 added cbindPad.r to _Rfunctions\datacleaning
## 
## #add in NAs to fill in missing rows for combining multiple data sources
## cbindPad <- function(x,y) {
## 	if(!is.vector(x)) {
## 		xx <- nrow(x)
## 		xy <- ncol(x)
## 		yy <- length(y)
## 		w <- matrix(NA,nrow=max(c(xx,yy)),ncol=xy+1)
## 		w[1:xx,1:xy] <- as.matrix(x)
## 		w[1:yy,(xy+1)] <- y
## 		return(w)
## 	} else {
## 		xx <- length(x)
## 		yy <- length(y)
## 		f <- which.max(c(xx,yy))
## 		if(f==1) y <- c(y,rep(NA,xx-yy))
## 		if(f==2) x <- c(x,rep(NA,yy-xx))
## 		w <- cbind(x,y)
## 		return(w)
## 	}
## 	
## }
## #############################################################################
## #MMM - Sept 18, 2014 added na.zero.r to _Rfunctions\datacleaning
## 
## na.zero<-function(x){
## 	for(i in 1:length(x[1,])){
## 		if(length(which(is.na(x[,i])))>0){
## 			x[which(is.na(x[,i])),i]<-0}
## 		}		
## 		return(x)
## } 
## #############################################################################  
## #MMM - Sept 18, 2014 added myrepo.r to _Rfunctions\packages
##   
## #set repository
## myrepo = getOption('repos')
## 	myrepo["CRAN"] = 'http://stat.ethz.ch/CRAN/'
## 	options(repos = myrepo)
## 	rm(myrepo)
## #############################################################################
## #MMM - Sept 18, 2014 added plot.nothing.r to _Rfunctions
## 
## plot.nothing<- function() {
## 	op<-par(mar=c(0,0,0,0))
## 	plot(c(0,1),c(0,1),ann=F,bty='n',type='n',xaxt='n',yaxt='n')
## 	par(op)
## }
## #############################################################################
## #MMM - Sept 18, 2014 added mult.windows.r to _Rfunctions
## 
## mult.windows<-function(mars=par()$mar,mfrows=par()$mfrow) {
## 	graphics.off()
## 	if(exists(".SavedPlots",where=1)==T){rm(.SavedPlots,pos=1)}
## 	par(mar=mars,mfrow=mfrows)
## 	windows(record=T)
## }	
## #############################################################################		
## #MMM - Sept 18, 2014 added .ls.objects.r to _Rfunctions
## 
## # improved list of objects
## .ls.objects <- function (pos = 1, pattern, order.by,
##                         decreasing=FALSE, head=FALSE, n=5) {
##     napply <- function(names, fn) sapply(names, function(x)
##                                          fn(get(x, pos = pos)))
##     names <- ls(pos = pos, pattern = pattern)
##     obj.class <- napply(names, function(x) as.character(class(x))[1])
##     obj.mode <- napply(names, mode)
##     obj.type <- ifelse(is.na(obj.class), obj.mode, obj.class)
##     obj.size <- napply(names, object.size)
##     obj.dim <- t(napply(names, function(x)
##                         as.numeric(dim(x))[1:2]))
##     vec <- is.na(obj.dim)[, 1] & (obj.type != "function")
##     obj.dim[vec, 1] <- napply(names, length)[vec]
##     out <- data.frame(obj.type, obj.size, obj.dim)
##     names(out) <- c("Type", "Size", "Rows", "Columns")
##     if (!missing(order.by))
##         out <- out[order(out[[order.by]], decreasing=decreasing), ]
##     if (head)
##         out <- head(out, n)
##     out
## }
## #############################################################################		
## #MMM - Sept 18, 2014 added lsos.r to _Rfunctions
## 
## # shorthand for .ls.objects.r
## lsos <- function(..., n=10) {
##     .ls.objects(..., order.by="Size", decreasing=TRUE, head=TRUE, n=n)
## }
## #############################################################################		
## #MMM - Sept 18, 2014 added lsos.r to _Rfunctions\datacleaning
## 
## dim.list<- function(list1) {
##  ab<-matrix(nrow=length(list1),ncol=2)
##  for(i in 1:length(list1)) {
## 	if(!is.null(dim(list1[[i]])))	ab[i,]<-(dim(list1[[i]]))
## 	else ab[i,1]<-(length(list1[[i]]))
## 	}
## 	return(ab)
## 	}
## #############################################################################		
## #MMM - Sept 18, 2014 added corr.prob.r to _Rfunctions
## 
## cor.prob <- function(X, dfr = nrow(X) - 2) {
## 	 R <- cor(X)
## 	 above <- row(R) < col(R)
## 	 r2 <- R[above]^2
## 	 Fstat <- r2 * dfr / (1 - r2)
## 	 R[above] <- 1 - pf(Fstat, 1, dfr)
## 	 R
## }
## #############################################################################	