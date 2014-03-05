# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Utilities
# ---------

# Extend `_` with our utility functions.
_.mixin {

  # Transform the given string into title case.
  capitalize: (str) ->
    return str unless str

    str.replace /\w+/g, (word) ->
      word[0].toUpperCase() + word[1..].toLowerCase()

}

# Enforcing the use of a template variable significantly optmizes the rendering of templates.
_.templateSettings.variable = 'ctx'
