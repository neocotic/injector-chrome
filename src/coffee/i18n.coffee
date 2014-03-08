# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Compatibility
# -------------

# Although we could easily just use `int17` as-is, it's probably best to integrate Chrome's
# internationalization implementation as it'll already be optimized using native code.
#
# For this reason, modify the internal classes of the `int17` library so that it interfaces with
# the Chrome API.
{Internationalization} = int17

# Use `chrome.i18n.getMessage` to retrieve the localized message for the specified `name`.
Internationalization::get = (name, subs...) ->
  return unless name

  message = chrome.i18n.getMessage(name, subs)

  if @escaping then @_.escape(message) else message

# Use `chrome.i18n.getAcceptLanguages` to asynchronously fetch all of the supported languages,
# optional specifying a `parent` locale for which only it's *children* should be retrieved.
Internationalization::languages = (parent, callback) ->
  if _.isFunction(parent)
    callback = parent
    parent   = null

  {languages}                    = @messenger
  {callOrThrow, filterLanguages} = @_

  if parent
    return @languages (err, languages) =>
      if err then callOrThrow(@, callback, err)
      else        callOrThrow(@, callback, null, filterLanguages(parent, languages))

  if languages.length
    return callOrThrow(@, callback, null, languages[..])

  chrome.i18n.getAcceptLanguages (languages) =>
    @messenger.languages = languages.sort()

    callOrThrow(@, callback, null, languages[..])

# Internalization setup
# ---------------------

# Ensure that the default value of the `messages` option is *not* an empty object in order to
# prevent any attempts to load message bundle resources.
#
# Also, use `chrome.i18n.getMessage` to derive the active locale.
window.i18n = int17.create().initSync
  locale:   chrome.i18n.getMessage('@@ui_locale')
  messages:
    prevent: {}
