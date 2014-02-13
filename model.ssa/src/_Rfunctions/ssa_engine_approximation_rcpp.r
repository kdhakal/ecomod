require(Rcpp)
sourceCpp( rebuild=TRUE, code='
#include <RcppArmadillo.h>
//[[Rcpp::depends(RcppArmadillo)]]
//[[Rcpp::export]]
using namespace Rcpp;

// inline functions here ... they just get replaced into the body below at compile time, e.g.:
// inline int randWrapper(const int n) { return floor(unif_rand()*n); }

List ssa_engine_approximation_rcpp ( List p, List res ) {
      
    RNGScope scope ;
    //Function r_cumsum( "cumsum" ) ;
    //Function r_sort( "sort" ) ;
    //Function r_sample("sample") ;  // load the R function to make this easier -- speed is equal to the Armadillo version

    Function RE("p$RE") ;  // load the R function to make this easier -- speed is equal to the Armadillo version
    
    // unpack the p and res input data
    List NU = as<List>( p["NU"] ) ;
    int nP = as<int>(p["nP"]) ;
    std::vector<unsigned int> insp = as<std::vector<unsigned int> >( p["insp"] ) ;
    std::vector<double> X = as<std::vector<double> >( res["X"] ) ;
    int nevaluations = as<int> (res["nevaluations"]) ;

    NumericVector P = as<NumericVector>( res["P"] ) ;
    double Ptotal = as<double>( res["P.total"] ) ;

    int nr = as<int>( p["nr"] ) ;
    int nc = as<int>( p["nc"] ) ;
    int nrc = as<int>( p["nrc"] ) ;

    int nr_lb = 1 ;  // lower bound when reflective boundary
    int nc_lb = 1 ;
    int nr_ub = nr -2 ; //upper bound when reflective boundary
    int nc_ub = nc -2 ;

    double Xtotal ;
    double tinc ;
    double tnew ;
    double simtime = 0 ;
    
    int i = 0;
    int j = 0;
    int tio = 0 ; 
    int tout = 0 ;
    int tend = as<int>( p["monitor"] ) ;
    int nsimultaneous_picks = as<int>(p["nsimultaneous.picks"]) ;
    int nt = nsimultaneous_picks ;
    int cr = 0 ;
    int cc = 0 ;
    int jn = 0 ;
    int ii=0; 
    int ro = 0 ;
    int co = 0 ;
    int no = 0 ;

    NumericVector o;
    int osize ;

    int ix;
    int ip;
    
    std::vector<unsigned int> tn ;
    NumericVector time_increment (nsimultaneous_picks) ;  // storage of proposed time increments
    std::vector<double> cumtn (nsimultaneous_picks) ; // CDF of time increments
    NumericVector reactions_choice(nsimultaneous_picks) ;  // storage of proposed reaction channel
    std::vector<double> tic (nsimultaneous_picks) ;
    std::vector<double> rn ;
    NumericVector prop (nP) ;
    std::vector<double> cumprop( nP ) ; // container for the CDF
    std::vector<unsigned int> J(nsimultaneous_picks) ; // randomly chosen cells, weighted by probabilities encoded in the CDF of propensities
    
    
    while ( simtime < tend ) {
        // begin with default dimensions and indices
        nt = nsimultaneous_picks ;
        tn = insp ;

        // choose reaction times
        time_increment = rexp(nt, Ptotal) ;
        tic = as< std::vector < double> > ( time_increment ); 

        // sum the time proposals
        tinc = std::accumulate( tic.begin(), tic.end(), 0.0) ; 
        tnew = simtime + tinc ;

        // if overshoot time to output, truncate and modify indices and length dimensions of choices
        if ( tnew > tout ) {
            std::partial_sum( tic.begin(), tic.end(), cumtn.begin() );  // compute CDF
            i=0 ;
            while (i < nt) {
              if ( cumtn[i] > tout ) break ;
              ++i ;
            }
            tn.resize(i) ;
            nt = i ; 
            tic.resize(i); 
            tinc = std::accumulate( tic.begin(), tic.end(), 0.0 ) ; // sum the time increment proposals
            tnew = simtime + tinc ;
        }
 
        if (nt > 0 ) {
            // choose reactions 
            reactions_choice = runif( nt ) ;
            rn =  as< std::vector < double> > (reactions_choice ); 

            prop = P/Ptotal ;
            std::partial_sum( prop.begin(), prop.end(), cumprop.begin() );  // compute CDF
            j=0 ;
            i=0 ;
            std::sort(rn.begin(), rn.end());
            while( i < nt ) {  // cycle over random numbers and classify reaction in sequence
              while ( j < nP &&  i < nt ) {
                  if ( rn[i] < cumprop[j] ) { 
                      J[i] = j+1 ;   // +1 as C uses 0 as first index
                      ++i ;
                  } else {
                      ++j ;
                  }
              }
              ++j ;
            }
           
            
            /* 
            remember that C++ indices begin with 0 vs R with 1
           
            C++ indices: row-major starting at 0 ..  http://en.wikipedia.org/wiki/Row-major_order
              | 1 2 3 |
              | 4 5 6 |
              i=0
              for (r in rows) {
                for (c in cols) {
                  i=i+1
                  u[r,c] = i

            R indices: col-major order indices starting at 1 
              | 1 3 5 |
              | 2 4 6 |
              i=0
              for (c in cols) {
                for (r in rows) {
                  i=i+1
                  u[r,c] = i


   
            ii = xi + xn*yi + xn*yn*zi = xi + xn*(yi + yn*zi) ; // xn = no x, etc for coords(xi,yi,zi)
            
              and the inverse ** NOTE using integer math: 
            
            xi =  ii % xn;               -- row no
            yi = (ii/xn) % yn;           -- col no
            zi =  ii / (xn*yn) ;         -- processes np

            So: (R-code follows)
     
            xn=nr=5
            yn=nc=8
            zn=np=3
            nrc=nr*nc
            nrcp=nr*nc*np

            
            u = NULL
            for( zi in 1:zn) {
            for( yi in 1:yn) {
            for( xi in 1:xn) {  ### i.e. rows are fastest changing 
              ii = ( (zi-1) * yn * xn) + ((yi-1) * xn) + (xi-1) ### Cindexing
              u = c(u, ii )   
            }}}
            u
        
            This array: 
            needs to be formed in the following manner to have the same R-structure
            p = array(1:nrcp, dim=c(nr, nc, np))
            ii=0
            for( zi in 1:zn) {
            for( yi in 1:yn) {
            for( xi in 1:xn) { ### i.e. rows are fastest changing 
                ii = ii+1
                p[xi,yi,zi] = ii 
            }}}
            p

            Testing: 
            J=10  # chose the index of P to recover
            jn  = floor( (J-1)/nrc ) + 1  # which reaction process
            jj = J - (jn-1)*nrc  # which cell 
            cc = floor( (jj-1)/nr ) + 1   # col
            cr = jj - (cc-1) * nr         # row
            print( paste( cr, cc, jn) )

            In C, indices start at 0
             xi = floor((J-1)%% xn)   ;           # -- row no
             yi = floor((J-1)/xn) %% yn ;          # -- col no
             zi = floor((J-1) / (xn*yn)) ;         # -- processes np
            print(paste(xi+1, yi+1, zi+1) )


            */

            // remap random element to correct location and process
            for ( int w=0 ; w < nt ; ++w ) {
                // determine focal cell coords in P
                ii = J[w] ;
                cr =  ii % nr;           //    -- row no
                cc = (ii/nr) % nc;       //    -- col no
                jn =  ii / nrc ;         // -- processes np
                
                o = NU( jn ) ;
                osize = o.size() / 3 ;

                for ( int m=0; m<osize; ++m) {
                 
                  // determine new candidate locations 
                  ro = cr + o( m*3  );  // # row of the focal cell
                  co = cc + o( m*3 + 2 ) ; // # column of the focal cell
                  
                  //# ensure boundary conditions are sane (reflective boundary conditions)
                  if (ro < 0) ro=nc_lb ;
                  if (ro >= nr) ro=nr_ub ;

                  if (co < 0) co= nc_lb ;
                  if (co >= nc) co = nc_ub; 

                  // update X-state space
                  ix = ro + (co * nr);      // X-indices
                  X[ix] = X[ix] + o( m*3 + 4 ) ;

                  // update P-state space and associated propensities in cells where state has changed, etc
                  for ( jj in nreactions) {
                    ip = ro + (co * nr) + jn * nrc ; // P-indices
                    P[ip] = RE(p, X[ix], ix);
                  }

                } // end for m
            }  //# end for w

            Ptotal = std::accumulate( P.begin(), P.end(), 0.0 ) ; // sum the time increment proposals
            simtime = tnew ;
            nevaluations =+ nt ;

            if ( tnew >= tout ) {
                // save output to disk ... ssa.db( ptype="save", out=res$X[], tio=tio, outdir=outdir, rn=rn )  ;
                tout = tout + t.censusinterval ;
                tio = tio + 1  # time as index ;
                Xtotal = std::accumulate( X.begin(), X.end(), 0.0 ) ; // sum the time increment proposals
                Rcout << tout << nevaluations << Ptotal << Xtotal << "\\n" ; // print some output to screen  ;
                out = List::create( _["X"]=X, _["P"]=P, _["P.total"]=Ptotal) ;
            } // end if output
          } // end if nt>0   
        } // end while

    List out; 
        out["x"] = i; 
        out["y"] = j;
    return(out);

}')


