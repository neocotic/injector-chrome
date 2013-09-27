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
        Snippets.fetch (snippets) ->
          callback { settings, editorSettings, snippets }

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
    tab:       'general_nav'
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

# Snippets
# --------

# Default Ace editor mode/language.
DEFAULT_MODE = 'javascript'

# A snippet to be injected into a specific host.  
# The snippet's code can be written in a number of supported languages and can be either be a
# script to be executed on the page or contain styles to be applied to it.
Snippet = models.Snippet = Backbone.Model.extend {

  defaults:
    code:     ''
    mode:     DEFAULT_MODE
    selected: no

  deselect: ->
    return $.Deferred().resolve() unless @get 'selected'

    @save(selected: no).done =>
      @trigger 'deselected', this

  groupName: ->
    _.chain(Snippet.modeGroups).keys().find(@inGroup, this).value()

  inGroup: (name) ->
    _.contains Snippet.modeGroups[name], @get 'mode'

  select: ->
    return $.Deferred().resolve() if @get 'selected'

    @save(selected: yes).done =>
      if @collection
        @collection.chain().without(this).invoke 'save', selected: no

      @trigger 'selected', this

  validate: (attributes) ->
    { host, mode } = attributes

    unless host
      'host is required'
    else unless mode
      'mode is required'

}, {

  defaultMode: DEFAULT_MODE

  # Map of mode groups.
  modeGroups: {}

  # Add all of the mode `groups` that are provided in their object form.
  mapModeGroups: (groups) ->
    _.each groups, (group) =>
      @modeGroups[group.name] = group.modes

  # Populates the map of mode groups with the values from `configuration.json`.  
  # Nothing happens if `Snippet.modeGroups` has already been populated.
  populateModeGroups: (callback) ->
    if _.isEmpty @modeGroups
      chrome.runtime.sendMessage { type: 'config' }, (config) =>
        @mapModeGroups config.editor.modeGroups

        do callback
    else
      do callback
}

# Collection of snippets created by the user.
Snippets = models.Snippets = Backbone.Collection.extend {

  chromeStorage: new Backbone.ChromeStorage 'Snippets', 'local'

  model: Snippet

  group: (name) ->
    Snippets.group this, name

}, {

  # Retrieve the **all** instances of `Snippet`.
  fetch: (callback) ->
    Snippet.populateModeGroups ->
      (snippets = new Snippets).fetch().then ->
        callback snippets

  # TODO: Document
  group: (snippets, name) ->
    if name
      snippets.filter (snippet) ->
        snippet.inGroup name
    else
      groups = {}

      _.each Snippet.modeGroups, (modes, name) =>
        groups[name] = snippets.filter (snippet) ->
          snippet.inGroup name

      groups

}
