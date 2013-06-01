# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Models
# ------

# Expose all models (and collections) that are used throughout the extension.  
# These are intentionally not added to the global object (i.e. `window`) to avoid cluttering that
# *namespace*.
models = window.models =

  # Convenience short-hand method for fetching all common models and collections.  
  # The `callback` function will be passed a map of the fetched instances.
  fetch: (callback) ->
    Settings.fetch (settings) ->
      EditorSettings.fetch (editorSettings) ->
        Scripts.fetch (scripts) ->
          callback { settings, editorSettings, scripts }

# Editor
# ------

# TODO: Document
editorSettingsLookup = null

# TODO: Document
# TODO: Add more advanced editor settings
EditorSettings = models.EditorSettings = Backbone.Model.extend {

  defaults:
    indentSize: 2
    lineWrap:   no
    softTabs:   yes
    theme:      'github'

}, {

  # TODO: Document
  fetch: (callback) ->
    (editorSettingsLookup ?= new EditorSettingsLookup).fetch().then ->
      editorSettingsLookup.add new EditorSettings unless editorSettingsLookup.length

      callback editorSettingsLookup.first()

}

# TODO: Document
EditorSettingsLookup = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'EditorSettings', 'sync'

  model: EditorSettings

# Settings
# --------

# TODO: Document
settingsLookup = null

# TODO: Document
Settings = models.Settings = Backbone.Model.extend {

  defaults:
    activeTab: 'general_nav'
    analytics: yes

}, {

  fetch: (callback) ->
    (settingsLookup ?= new SettingsLookup).fetch().then ->
      settingsLookup.add new Settings unless settingsLookup.length

      callback settingsLookup.first()

}

# TODO: Document
SettingsLookup = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'Settings', 'sync'

  model: Settings

# Scripts
# -------

# TODO: Document
DEFAULT_MODE = 'javascript'

# TODO: Document
Script = models.Script = Backbone.Model.extend {

  defaults:
    code: ''
    mode: DEFAULT_MODE

  validate: (attributes) ->
    { host, mode } = attributes

    unless host
      'host is required'
    else unless mode
      'mode is required'

}, {

  defaultMode: DEFAULT_MODE

}

# TODO: Document
Scripts = models.Scripts = Backbone.Collection.extend {

  chromeStorage: new Backbone.ChromeStorage 'Scripts', 'local'

  model: Script

}, {

  fetch: (callback) ->
    (scripts = new Scripts).fetch().then ->
      callback scripts

}
