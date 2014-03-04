# [Injector](http://neocotic.com/injector)  
# (c) 2014 Alasdair Mercer  
# Freely distributable under the MIT license

# Snippet Injector
# ----------------

# Derive the host name for the current page.
host = location.host.replace /^www\./, ''

# Retrieve any JavaScript and CSS code that is to be injected into the current page.
chrome.runtime.sendMessage { host, type: 'injection' }, (response) ->
  head        = document.querySelector 'head'
  { css, js } = response

  # Create an element with the given name and insert it in to the document `<head>`.
  # The new element will contain only the `html` provided.
  appendNewElement = (tagName, html) ->
    el = document.createElement tagName
    el.innerHTML = html

    head.appendChild el

  # Insert `<style>` elements in to the DOM for each CSS code.
  for code in css
    appendNewElement 'style', code

  # Insert `<script>` elements in to the DOM for each JavaScript code.  
  # Scripts are executed within a closed function to prevent variables accidentally becoming
  # global and potentially causing conflicts with libraries used on the current page.
  for code in js
    appendNewElement 'script', """
      (function() {
      #{code}
      })();
    """
