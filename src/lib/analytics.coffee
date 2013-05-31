# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Private constants
# -----------------

# Code for Script Runner analytics account.
ACCOUNT = 'TODO'
# Source URL of the analytics script.
SOURCE  = 'https://ssl.google-analytics.com/ga.js'

# Analytics setup
# ---------------

analytics = window.analytics = new class Analytics extends utils.Class

  # Public functions
  # ----------------

  # Initialize analytics, potentially adding it to the current page.
  init: ->
    # Setup tracking details for analytics.
    _gaq = window._gaq ?= []
    _gaq.push ['_setAccount', ACCOUNT]
    _gaq.push ['_trackPageview']

    # Inject script to capture analytics.
    ga = document.createElement 'script'
    ga.async = 'async'
    ga.src   = SOURCE
    script = document.getElementsByTagName('script')[0]
    script.parentNode.insertBefore ga, script

  # Remove analytics from the current page.
  remove: ->
    # Delete scripts used to capture analytics.
    for script in document.querySelectorAll "script[src='#{SOURCE}']"
      script.parentNode.removeChild script

    # Remove tracking details for analytics.
    delete window._gaq

  # Create an event with the information provided and track it in analytics.
  track: (category, action, label, value, nonInteraction) ->
    return unless window._gaq

    event = ['_trackEvent']
    # Add the required information.
    event.push category
    event.push action
    # Add the optional information where possible.
    event.push label          if label?
    event.push value          if value?
    event.push nonInteraction if nonInteraction?

    # Add the event to analytics.
    _gaq = window._gaq ?= []
    _gaq.push event
