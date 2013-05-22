# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Private classes
# ---------------

# `Class` makes for more readable logs etc. as it overrides `toString` to output the name of the
# implementing class.
class Class

  # Override the default `toString` implementation to provide a cleaner output.
  toString: ->
    @constructor.name

# Utilities setup
# ---------------

utils = window.utils = new class Utils extends Class

  # Public functions
  # ----------------

  # Create a safe wrapper for the callback specified function.
  callback: (fn) ->
    (args...) ->
      if _.isFunction fn
        fn args...
        true

  # Transform the given string into title case.
  capitalize: (str) ->
    return str unless str

    str.replace /\w+/g, (word) ->
      word[0].toUpperCase() + word[1..].toLowerCase()

# Public classes
# --------------

# Objects within the extension should extend this class wherever possible.
utils.Class = Class
