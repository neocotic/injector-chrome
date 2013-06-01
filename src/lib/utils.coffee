# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Utilities setup
# ---------------

utils = window.utils = new class Utils

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

  # Convenient shorthand for `chrome.extension.getURL`.
  url: ->
    chrome.extension.getURL arguments...
