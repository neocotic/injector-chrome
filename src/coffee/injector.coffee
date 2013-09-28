# [Injector](http://neocotic.com/injector)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Snippet Injector
# ----------------

# Execute the given code.  
# The code is provided as an unnamed argument to avoid it being included in the scope of the
# execution.
executeScript = ->
  eval arguments[0]

# Attempt to retrieve each `Snippet` for the current host domain and inject them as safely as
# possible.
models.Snippets.fetch (snippets) ->
  host      = location.host.replace /^www\./, ''
  snippets  = snippets.where { host }
  variables = [
    'Backbone'
    'CoffeeScript'
    'less'
    'chrome'
    'models'
  ]

  { scripts, styles } = models.Snippets.group snippets

  # Inject `<style>` elements for each style, containing its (potentially compiled) CSS.
  unless _.isEmpty styles
    $head  = $ 'head'
    parser = new less.Parser

    applyStyle = (code) ->
      $head.append $ '<style>', html: code

    _.each styles, (style) ->
      mode = style.get 'mode'
      code = style.get 'code'

      if mode is 'less' then parser.parse code, (error, tree) ->
        throw error if error

        applyStyle tree.toCSS()
      else
        applyStyle code

  # Execute the JavaScript code for each script.  
  # In some cases, the code may have been a result of a compilation.
  unless _.isEmpty snippets
    js = _.reduce snippets, (snippet) ->
      mode = snippet.get 'mode'
      code = snippet.get 'code'
      code = CoffeeScript.compile code if mode is 'less'

      """
        (function() {
          #{code}
        })();
      """

    # Execute the specified code with as limited a scope as possible, removing all unnecessary or
    # dangerous global variables.
    _.each variables, (variable) ->
      window[variable] = undefined

    executeScript js
