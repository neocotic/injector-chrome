# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Helpers
# -------

# Attempt to select a tab in the current window displaying a page whose location begins with `url`.
#
# If no existing tab exists, a new one is created.
activateTab = (url, callback) ->
  # Retrieve the tabs of last focused window to check for an existing one with a *matching* URL.
  chrome.windows.getLastFocused { populate: yes }, (win) ->
    {tabs} = win

    # Try to find an existing tab that begins with `url`.
    for tab in tabs when not tab.url.indexOf(url)
      existing = tab
      break

    if existing?
      # Found one! Now to select it.
      chrome.tabs.update(existing.id, { active: yes })
      callback?(existing)
    else
      # Ach well, let's just create a brand-spanking new one.
      chrome.tabs.create { windowId: win.id, url, active: yes }, (tab) ->
        callback?(tab)

# Derive the host name from the specified `url`.
getHost = (url) ->
  $.url(url).attr('host').replace(/^www\./, '')

# Compilers
# ---------

# Reusable instance of the LESS parser used to compile LESS code in to CSS.
lessParser = null

# Compilers that map to supported editor modes.
#
# Each compiler should compile into either JavaScript or CSS code, depending on the nature of the
# language.
compilers = {

  # Compile the CoffeeScript `code` provided in to JavaScript.
  coffee: (code, callback) ->
    try
      code = CoffeeScript.compile(code, { bare: yes })
      callback(null, code)
    catch error
      callback(error)

  # Compile the LESS `code` provided in to CSS.
  less: (code, callback) ->
    lessParser ?= new less.Parser()
    lessParser.parse code, (error, tree) ->
      if error then callback(error)
      else          callback(null, tree.toCSS())

}

# Compile the code of the specified `snippet`, if required.
#
# If the `snippet` mode does not require compilation, the `code` will be passed back as-is.
compileSnippet = (snippet, callback) ->
  {code, mode} = snippet.pick('code', 'mode')

  if compilers[mode]
    compilers[mode](code, callback)
  else
    callback(null, code)

# Events
# ------

# Retrieve the contents of the specified JSON `file` that is relative to this extension.
fetchJSON = (file, callback) ->
  $.getJSON(chrome.extension.getURL(file))
  .done (data) ->
    callback(null, data)
  .fail (jqXHR, textStatus, error) ->
    callback(error)

  # Indicate that we intend on responding to the request.
  true

# Retrieve all of the snippets that are associated with a given `host`.
#
# The snippets are grouped based on their modes (languages) and compiled so that their code can be
# quickly and easily injected in to the requesting page.
fetchSnippets = (host, callback) ->
  models.Snippets.fetch (snippets) ->
    snippets          = snippets.where({ host })
    {scripts, styles} = models.Snippets.group(snippets)

    async.parallel {
      css: (done) ->
        async.mapSeries(styles, compileSnippet, done)

      js: (done) ->
        async.mapSeries(scripts, compileSnippet, done)
    }, callback

  # Indicate that we intend on responding to the request.
  true

# Open the Options page when the browser action is clicked.
chrome.browserAction.onClicked.addListener (tab) ->
  {options_page} = chrome.runtime.getManifest()

  activateTab(chrome.extension.getURL(options_page))

# Add message listener to communicate with other pages within the extension.
chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  # Wrapper for incorporating the asynchronous pattern of the `async` library.
  callback = (error, args...) ->
    throw error if error?

    sendResponse(args...)

  # The request needs to be handled differently based on its type.
  switch request.type
    when 'config'    then fetchJSON('configuration.json', callback)
    when 'injection' then fetchSnippets(getHost(request.url), callback)
    else false
