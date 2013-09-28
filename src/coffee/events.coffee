# [Injector](http://neocotic.com/injector)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Helpers
# -------

# Attempt to select a tab in the current window displaying a page whose location begins with `url`.  
# If no existing tab exists a new one is created.
activateTab = (url, callback) ->
  # Retrieve the tabs of last focused window to check for an existing one with a *matching* URL.
  chrome.windows.getLastFocused populate: yes, (win) ->
    { tabs } = win

    # Try to find an existing tab that begins with `url`.
    for tab in tabs when not tab.url.indexOf url
      existing = tab
      break

    if existing?
      # Found one! Now to select it.
      chrome.tabs.update existing.id, active: yes
      callback? existing
    else
      # Ach well, let's just create a brand-spanking new one.
      chrome.tabs.create { windowId: win.id, url, active: yes }, (tab) ->
        callback? tab

# Events
# ------

# Open the Options page when the browser action is clicked.
chrome.browserAction.onClicked.addListener (tab) ->
  activateTab chrome.extension.getURL 'options.html'

# Add message listener to communicate with other pages within the extension.
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  # Retrieve the data configuration from the configuration file.
  if request.type is 'config'
    $.getJSON chrome.extension.getURL('configuration.json'), (config) ->
      sendResponse config

  true
