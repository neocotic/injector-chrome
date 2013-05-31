# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Editor
# ------

# TODO: Document
editorSettingsLookup = null

# TODO: Document
# TODO: Add more advanced editor settings
EditorSettings = window.EditorSettings = Backbone.Model.extend {

  defaults:
    indentSize: 2
    lineWrap:   no
    softTabs:   yes
    theme:      'github'

}, {

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
Settings = window.Settings = Backbone.Model.extend {

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
Script = window.Script = Backbone.Model.extend {

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
Scripts = window.Scripts = Backbone.Collection.extend {

  chromeStorage: new Backbone.ChromeStorage 'Scripts', 'local'

  model: Script

}, {

  fetch: (callback) ->
    (scripts = new Scripts).fetch().then ->
      callback scripts

}

# Models
# ------

# TODO: Document
models = window.models =

  # TODO: Document
  fetch: (callback) ->
    Settings.fetch (settings) ->
      EditorSettings.fetch (editorSettings) ->
        Scripts.fetch (scripts) ->
          callback { settings, editorSettings, scripts }
