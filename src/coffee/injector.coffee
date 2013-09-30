# [Injector](http://neocotic.com/injector)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Snippet Injector
# ----------------

# Derive the host name for the current page.
host = location.host.replace /^www\./, ''

# Retrieve any JavaScript and CSS code that is to be injected into the current page.
chrome.runtime.sendMessage { host, type: 'injection' }, (response) ->
  head        = document.querySelector 'head'
  { css, js } = response

  # Insert `<style>` elements in to the DOM for each CSS code.
  for code in css
    el = document.createElement 'style'
    el.innerHTML = code

    head.appendChild el

  # Insert `<script>` elements in to the DOM for each JavaScript code.  
  # Scripts are executed within a closed function to prevent variables accidentally becoming
  # global and potentially causing conflicts with libraries used on the current page.
  for code in js
    el = document.createElement 'script'
    el.innerHTML = """
      (function() {
        #{code}
      })();
    """

    head.appendChild el
