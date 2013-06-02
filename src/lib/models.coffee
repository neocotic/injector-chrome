# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Models
# ------

# Expose all models (and collections) that are used throughout the extension.  
# These are intentionally not added to the global object (i.e. `window`) to avoid cluttering that
# *namespace*.
models = window.models =

  # Convenience short-hand method for retrieving all common models and collections.  
  # The `callback` function will be passed a map of the fetched instances.
  fetch: (callback) ->
    Settings.fetch (settings) ->
      EditorSettings.fetch (editorSettings) ->
        Scripts.fetch (scripts) ->
          callback { settings, editorSettings, scripts }

# Editor
# ------

# Singleton instance of the `EditorSettingsLookup` collection.
editorSettingsLookup = null

# The settings associated with the Ace editor.
EditorSettings = models.EditorSettings = Backbone.Model.extend {

  defaults:
    indentSize: 2
    lineWrap:   no
    softTabs:   yes
    theme:      'github'

}, {

  # Retrieve the singleton instance of the `EditorSettings` model.
  fetch: (callback) ->
    (editorSettingsLookup ?= new EditorSettingsLookup).fetch().then ->
      editorSettingsLookup.add new EditorSettings unless editorSettingsLookup.length

      callback editorSettingsLookup.first()

}

# Lookup collection used for retrieving a singleton instance of the `EditorSettings` model.
EditorSettingsLookup = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'EditorSettings', 'sync'

  model: EditorSettings

# Settings
# --------

# Singleton instance of the `SettingsLookup` collection.
settingsLookup = null

# The general settings that can be configured (or are related to) the options page.
Settings = models.Settings = Backbone.Model.extend {

  defaults:
    activeTab: 'general_nav'
    analytics: yes

}, {

  # Retrieve the singleton instance of the `Settings` model.
  fetch: (callback) ->
    (settingsLookup ?= new SettingsLookup).fetch().then ->
      settingsLookup.add new Settings unless settingsLookup.length

      callback settingsLookup.first()

}

# Lookup collection used for retrieving a singleton instance of the `Settings` model.
SettingsLookup = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'Settings', 'sync'

  model: Settings

# Scripts
# -------

# Default Ace editor mode/language.
DEFAULT_MODE = 'javascript'

# A script to be executed on a specific host.  
# The script's code can be written in any supported language that compiles to JavaScript.
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

# Collection of scripts created by the user.
Scripts = models.Scripts = Backbone.Collection.extend {

  chromeStorage: new Backbone.ChromeStorage 'Scripts', 'local'

  model: Script

}, {

  # Retrieve the **all** instances of `Script`.
  fetch: (callback) ->
    (scripts = new Scripts).fetch().then ->
      callback scripts

}
