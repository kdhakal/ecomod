adapt.optim = function(inits, ... ) { 
  # simple wrapper to handle inits and error function
  adapt.result = adapt.core(inits)
  return (adapt.result$error)
}


