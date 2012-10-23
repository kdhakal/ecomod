
	# local, custumized starting functions and conditions

	# base environment
  lib.init = search()
  obj.init = ls()
  namespaces.init = loadedNamespaces()
 


# Run commands without parentheses by changing class of the function into a class "command"

  print.command <- function(x) {
      default.args <- attr(x, "default.args")
      if (!length(default.args)) default.args <- list()
      res <- do.call(x, default.args, envir = parent.frame())
      if(!is.null(res)) print(res)
  }

  class(search) <- c("command", class(search))
  class(searchpaths) <- c("command", class(searchpaths))

  class(quit)  <- c("command", class(quit))
  attr(quit, "default.args") <- list(save="no")
  q <- exit <- quit 

  class(ls) <- c("command", class(ls))
  attr(ls, "default.args") <- list(all = TRUE)

  clear <- function() { system("clear") ; NULL }
  class(clear) <- c("command", class(clear))


	# used to load libraries conveniently
	loadlibraries = function( libs ) {
		for ( l in libs ) require( l, character.only=T )
	}
	

# determine project direcotry string
	project.directory = function( name ) {
		return( file.path( projects, name ) )  ## defined in local environment variables
	}



	# used to load local functions conveniently
	loadfunctions = function( projectname, filepattern=NULL, directorypattern=NULL, functionpattern=NULL, keydirectories = NULL ) {

		projectdirectory = project.directory( name=projectname )
		searchdirectories = file.path( projectdirectory, "src" )

		if (is.null( filepattern ) ) filepattern="\\.r$"
		
		if (!is.null(functionpattern)) {
			projectfiles = list.files( path=searchdirectories, pattern=filepattern, full.names=T, recursive=T,  ignore.case=T, include.dirs=F )
			keep = grep ( functionpattern, projectfiles, ignore.case =T )
			if (length(keep)>0) {
				projectfiles = projectfiles[keep]
				for ( nm in projectfiles ) source( file=nm )
				return( projectfiles )
			}
			return( paste( "File not found", functionpattern ) ) 
		}

		if (is.null(keydirectories)) {
			# determine correct directory .. first look for a set of key directories, if not then scan all files
			keydirectories = c("r", "\\.r", "\\_r", "rfunc", "rfunctions", ".rfunctions", "\\_rfunctions" )
			keydirectories = paste( "\\<", keydirectories, "\\>", sep="")
		}
		
		if ( is.null(directorypattern )) {
			searchdirectories = list.dirs(path=searchdirectories, full.names=TRUE, recursive=TRUE)
			md = NULL
			for ( kd in keydirectories) {
				md = c( md, grep ( kd, searchdirectories, ignore.case =T ) )
				md = unique( md )
			}
			if (length(md) > 0 ) searchdirectories = searchdirectories[ md ]
		}

		projectfiles = NULL
		projectfiles = list.files( path=searchdirectories, pattern=filepattern, full.names=T, recursive=T,  ignore.case=T, include.dirs=F )
		projectfiles = unique( projectfiles )


		# remove archived functions, etc.
		toremove = c("retired", "_archive", "test", "orphan", "request", "example" )
		rem  = NULL
		for (i in toremove) {
			rem0 = grep ( i, projectfiles,  ignore.case =T ) 
			if (length( rem0)>0 ) rem = c( rem, rem0)
		}
		if ( length(rem)>0 ) {
			rem = unique(rem)
			projectfiles = projectfiles[-rem]
		}

	  if ( length(projectfiles) > 0 ) {
			for ( nm in projectfiles ) source( file=nm )
			return(projectfiles ) 
		}
	}



	# default start/stop
	.First <- function() {
		# start up functions add here
	}

	.Last <- function(){
	  graphics.off()                        # a small safety measure.
	  # cat(paste(date(),"\nBye\n"))       # clean up here
	}

