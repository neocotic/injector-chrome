# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Private constants
# -----------------

# Map of HTML entities for escaping.  
# **Note:** This is a direct port of the private constant used by `int17`.
ENTITY_MAP =
  '&':  '&amp;'
  '<':  '&lt;'
  '>':  '&gt;'
  '"':  '&quot;'
  '\'': '&#x27;'
  '/':  '&#x2F;'
# Regular expression used for escaping HTML entities.  
# **Note:** This is a direct port of the private constant used by `int17`.
R_ESCAPE   = /// [ #{_.keys(ENTITY_MAP).join ''} ] ///g
# Regular expression used to extract the parent segment from locales.
R_PARENT   = /^([^\-_]+)[\-_]/

# Private functions
# -----------------

# Call `callback` in the specified `context` if it's a valid function.  
# All other arguments will be passed on to `callback` but if the first argument is non-null this
# indicates an error which will be thrown if `callback` is invalid.  
# **Note:** This is a direct port of the private function used by `int17`.
callOrThrow = (context, callback, args...) ->
  if _.isFunction callback
    callback.apply context, args
  else if args[0]
    throw args[0]

# Escape the `string` provided to HTML interpolation.  
# **Note:** This is a direct port of the private function used by `int17`.
escape = (string) ->
  return '' unless string

  "#{string}".replace R_ESCAPE, (match) ->
    ENTITY_MAP[match]

# Filter only `languages` that extend from the specified `parent` locale.  
# **Note:** This is a direct port of the private function used by `int17`.
filterLanguages = (parent, languages) ->
  results = []

  for language in languages
    match = language.match R_PARENT
    results.push language if match and match[1] is parent

  results

# Internalization setup
# ---------------------

# Although we could easily just use `int17` as-is, it's probably best to integrate Chrome's
# internationalization implementation as it'll already be optimized using native code.  
# However, this means that the `Internationalization` and `Messenger` classes used internally by
# `int17` need to be modified to interace with the Chrome API.
i18n = window.i18n = int17.create()

# Compatibility
# -------------

# Use `chrome.i18n.getMessage` to retrieve the localized message for the specified `name`.
i18n.get = (name, subs...) ->
  return unless name

  message = chrome.i18n.getMessage name, subs
  if @escaping then escape message else message

# Use `chrome.i18n.getAcceptLanguages` to asynchronously fetch all of the supported languages,
# optional specifying a `parent` locale for which only it's *children* should be retrieved.
i18n.languages = (parent, callback) ->
  if _.isFunction parent
    callback = parent
    parent   = null

  {languages} = @messenger

  if parent
    return @languages (err, languages) =>
      if err then callOrThrow this, callback, err
      else        callOrThrow this, callback, null, filterLanguages parent, languages

  if languages.length
    return callOrThrow this, callback, null, languages[..]

  chrome.i18n.getAcceptLanguages (languages) =>
    @messenger.languages = languages.sort()

    callOrThrow this, callback, null, languages[..]

# Reconfigure this `Messenger` so that it has an empty `messages` map, preventing any attempts to
# load the resources.
i18n.messenger.reconfigure = ->
  @messages = {}

  this

# Initialize the `Internationalization` instance synchronously, providing the locale that has
# already been derived by Chrome.
i18n.initSync locale: chrome.i18n.getMessage '@@ui_locale'
