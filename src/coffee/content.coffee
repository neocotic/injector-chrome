# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Content Script
# --------------

# Derive the host name for the current page.
host = location.host.replace /^www\./, ''

# Retrieve any JavaScript and CSS code that is to be injected into the current page.
chrome.runtime.sendMessage { host, type: 'injection' }, (response) ->
  body      = document.querySelector 'body'
  head      = document.querySelector 'head'
  {css, js} = response

  # Create an element with the given name and insert it in to the `parent` element.
  #
  # The new element will contain only the `html` provided.
  appendNewElement = (tagName, parent, html) ->
    el = document.createElement tagName
    el.innerHTML = html

    parent.appendChild el

  # Insert `<style>` elements in to the DOM for each CSS code.
  for code in css
    appendNewElement 'style', head, code

  # Insert `<script>` elements in to the DOM for each JavaScript code.
  #
  # Scripts are executed within a closed function to prevent variables accidentally becoming global
  # and potentially causing conflicts with libraries used on the current page.
  for code in js
    appendNewElement 'script', body, """
      (function() {
      #{code}
      })();
    """
