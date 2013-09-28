# [Injector](http://neocotic.com/injector)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Analytics
# ---------

# Analytics capture end-user interactions and usage details which can be used to improve the
# extension.  
# Although enabled by default, the user can disable the capturing of this information via the
# options page.
analytics = window.analytics =

  # Source URL of the analytics script.
  source: 'https://ssl.google-analytics.com/ga.js'

  # Add analytics to the current page.
  add: (account) ->
    # Setup tracking details for analytics.
    _gaq = window._gaq ?= []
    _gaq.push [ '_setAccount', account ]
    _gaq.push [ '_trackPageview' ]

    # Inject script to capture analytics.
    ga = document.createElement 'script'
    ga.async = 'async'
    ga.src   = analytics.source

    script = document.getElementsByTagName('script')[0]
    script.parentNode.insertBefore ga, script

  # Remove analytics from the current page.
  remove: ->
    # Delete scripts used to capture analytics.
    for script in document.querySelectorAll "script[src='#{analytics.source}']"
      script.parentNode.removeChild script

    # Remove tracking details for analytics.
    delete window._gaq

  # Create an event with the information provided and track it in analytics.
  track: (category, action, label, value, nonInteraction) ->
    return unless window._gaq

    event = [ '_trackEvent' ]
    # Add the required information.
    event.push category
    event.push action
    # Add the optional information, where possible.
    event.push label          if label?
    event.push value          if value?
    event.push nonInteraction if nonInteraction?

    # Add the event to analytics.
    window._gaq.push event
