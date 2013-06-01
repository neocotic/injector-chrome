# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Script Runner
# -------------

# Evaluate/execute the given code.  
# The code is provided as an unnamed argument to avoid it being included in the scope of the
# execution.
exec = ->
  eval arguments[0]

# Attempt to retrieve a `Script` for the current host domain and execute it as safely as possible.
models.Scripts.fetch (scripts) ->
  host      = location.host.replace /^www\./, ''
  script    = scripts.findWhere { host }
  variables = [
    'Backbone'
    'CoffeeScript'
    'chrome'
    'models'
  ]

  if script
    # Compile the code if necessary before it can be evaluated.
    code = script.get 'code'
    code = CoffeeScript.compile code if script.get('mode') is 'coffee'

    # Execute the specified code with as limited a scope as possible, removing all unnecessary or
    # dangerous global variables.
    _(variables).each (variable) ->
      window[variable] = undefined

    exec code
