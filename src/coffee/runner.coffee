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

# Attempt to retrieve each `Script` for the current host domain and execute them as safely as
# possible.
models.Scripts.fetch (scripts) ->
  host      = location.host.replace /^www\./, ''
  scripts   = scripts.where { host }
  variables = [
    'Backbone'
    'CoffeeScript'
    'chrome'
    'models'
  ]

  unless _.isEmpty scripts
    # Ensure all code requiring compilation are compiled prior to evaluated.
    compilation = _(scripts).map (script) ->
      code = script.get 'code'
      code = CoffeeScript.compile code if script.get('mode') is 'coffee'

      """
        (function() {
          #{code}
        }).call(this);
      """

    # Execute the specified code with as limited a scope as possible, removing all unnecessary or
    # dangerous global variables.
    _(variables).each (variable) ->
      window[variable] = undefined

    exec compilation.join '\n'
