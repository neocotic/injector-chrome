# [Script Runner](http://neocotic.com/script-runner)  
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

# TODO: Document
chrome.browserAction.onClicked.addListener (tab) ->
  activateTab chrome.extension.getURL 'options.html'
