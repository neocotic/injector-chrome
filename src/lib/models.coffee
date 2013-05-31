# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Editor
# ------

# TODO: Document
editorSettingsLookup = null

# TODO: Document
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
# TODO: Add section for advanced editor settings
# TODO: Move editor settings into separate model
Settings = window.Settings = Backbone.Model.extend {

  defaults:
    activeTab:        'general_nav'
    analytics:        yes
    editorIndentSize: 2
    editorLineWrap:   no
    editorSoftTabs:   yes
    editorTheme:      'github'

  initialize: ->
    @on 'change:analytics', @updateAnalytics
    @on """
      change:editorIndentSize
      change:editorLineWrap
      change:editorSoftTabs
      change:editorTheme
    """.replace(/\n/g, ' '), @updateEditor

    do @updateAnalytics

  updateAnalytics: ->
    if @get 'analytics'
      analytics.init()
    else
      analytics.remove()

  updateEditor: ->
    options.app.editor.updateSettings()

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
    mode: Script.defaultMode

  validate: (attributes) ->
    { host, mode } = attributes

    unless host
      'host is required'
    else unless mode
      'mode is required'
    else unless _(options.config.editor.modes).contains mode
      'mode is unrecognized'

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
