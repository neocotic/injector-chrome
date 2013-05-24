# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Storage
# -------

# TODO: Document
listeners = {}

# TODO: Document
trigger = (area, changes) ->
  handlers = listeners[area] ? {}

  for field, change of changes
    {newValue, oldValue} = change

    _(handlers['*']).each (handler) ->
      {callback, context} = handler
      callback.call context, field, newValue, oldValue

    _(handlers[field]).each (handler) ->
      {callback, context} = handler
      callback.call context, newValue, oldValue

# TODO: Document
chrome.storage.onChanged.addListener (changes, area) ->
  trigger area, changes

# TODO: Document
class Storage extends utils.Class

  # TODO: Document
  clear: (area, callback) ->
    chrome.storage[area].clear ->
      callback?()

  # TODO: Document
  diff: (newValue = {}, oldValue = {}) ->
    changes = {}

    for field, value of newValue when value isnt oldValue[field]
      changes[field] =
        newValue: value
        oldValue: oldValue[field]

    for field, value of oldValue when not _(newValue).has field
      changes[field] =
        newValue: undefined
        oldValue: value

    changes

  # TODO: Document
  get: (area, name, defaultValue, callback) ->
    if _.isFunction defaultValue
      callback     = defaultValue
      defaultValue = null

    key = if defaultValue? then _([name]).object [defaultValue] else name

    chrome.storage[area].get key, (items) ->
      callback items[name]

  # TODO: Document
  init: (area, name, defaultValue, callback) ->
    key = _([name]).object [defaultValue]

    chrome.storage[area].get key, (items) ->
      chrome.storage[area].set items, ->
        callback?()

  # TODO: Document
  onChanged: (area, name, context, callback) ->
    if _.isFunction context
      callback = context
      context  = this

    listeners[area] ?= {}
    (listeners[area][name] ?= []).push {callback, context}

  # TODO: Document
  remove: (area, name, callback) ->
    chrome.storage[area].remove name, ->
      callback?()

  # TODO: Document
  rename: (area, oldName, newName, defaultValue, callback) ->
    if _.isFunction defaultValue
      callback     = defaultValue
      defaultValue = null

    key = if defaultValue? then _([oldName]).object [defaultValue] else oldName

    chrome.storage[area].get key, (items) ->
      chrome.storage[area].remove oldName, ->
        items[newName] = items[oldName]
        delete items[oldName]

        chrome.storage[area].set items, ->
          callback?()

  # TODO: Document
  set: (area, name, value, callback) ->
    if _.isFunction value
      callback = value
      value    = null

    items = if _.isObject name then name else _([name]).object [value]

    chrome.storage[area].set items, ->
      callback?()

  # TODO: Document
  trigger: trigger

# Store setup
# -----------

store = window.store = new Storage

# TODO: Document
for area in ['local', 'sync']
  areaStore = store[area] = new Storage

  for method in ['clear', 'get', 'init', 'onChanged', 'remove', 'rename', 'set', 'trigger']
    areaStore[method] = _.partial areaStore[method], area
