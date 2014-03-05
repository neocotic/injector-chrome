# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Models
# ------

# Expose all models (and collections) that are used throughout the extension.
#
# These are intentionally not added to the global object (i.e. `window`) to avoid cluttering that
# *namespace*.
models = window.models =

  # Convenience short-hand method for retrieving all common models and collections.
  #
  # The `callback` function will be passed a map of the fetched instances.
  fetch: (callback) ->
    Settings.fetch (settings) ->
      EditorSettings.fetch (editorSettings) ->
        Snippets.fetch (snippets) ->
          callback { settings, editorSettings, snippets }

# Editor
# ------

# The settings associated with the Ace editor.
EditorSettings = models.EditorSettings = Injector.SingletonModel.extend {

  # Store the editor settings remotely.
  storage:
    name: 'EditorSettings'
    type: 'sync'

  # Default attributes for the editor settings.
  defaults:
    indentSize: 2
    lineWrap:   no
    softTabs:   yes
    theme:      'chrome'

}

# Settings
# --------

# The general settings that can be configured (or are related to) the options page.
Settings = models.Settings = Injector.SingletonModel.extend {

  # Store the general settings remotely.
  storage:
    name: 'Settings'
    type: 'sync'

  # Default attributes for the general settings.
  defaults:
    analytics: yes
    tab:       'snippets_nav'

}

# Snippets
# --------

# Default Ace editor mode/language.
DEFAULT_MODE = 'javascript'

# A snippet to be injected into a specific host.
#
# The snippet's code can be written in a number of supported languages and can be either be a
# script to be executed on the page or contain styles to be applied to it.
Snippet = models.Snippet = Injector.Model.extend {

  # Default attributes for a snippet.
  defaults:
    code:     ''
    mode:     DEFAULT_MODE
    selected: no

  # Deselect this snippet, but only if it is currently selected.
  deselect: ->
    if @get 'selected'
      @save selected: no
      .done =>
        @trigger 'deselected', @
    else
      $.Deferred().resolve()

  # Indicate whether or not the mode of this snippet falls under a group with the given `name`.
  inGroup: (group, name) ->
    name = group if _.isString group

    _.contains Snippet.modeGroups[name], @get 'mode'

  # Select this snippet, but only if it is *not* already selected.
  select: ->
    if @get 'selected'
      $.Deferred().resolve()
    else
      @save selected: yes
      .done =>
        @collection?.chain()
        .without @
        .invoke 'save', selected: no

        @trigger 'selected', @

  # Validate that the attributes of this snippet are valid.
  validate: (attributes) ->
    {host, mode} = attributes

    unless host
      'host is required'
    else unless mode
      'mode is required'

}, {

  # Expose the default Ace editor mode/language publically.
  defaultMode: DEFAULT_MODE

  # Map of mode groups.
  modeGroups: {}

  # Add all of the mode `groups` that are provided in their object form.
  #
  # If a group already exists, it's original value will be overridden.
  mapModeGroups: (groups) ->
    @modeGroups[group.name] = group.modes for group in groups

  # Populates the map of mode groups with the values from the configuration file.
  #
  # Nothing happens if `Snippet.modeGroups` has already been populated.
  populateModeGroups: (callback) ->
    if _.isEmpty @modeGroups
      $.getJSON chrome.extension.getURL('configuration.json'), (config) =>
        @mapModeGroups config.editor.modeGroups

        do callback
    else
      do callback
}

# Collection of snippets created by the user.
Snippets = models.Snippets = Injector.Collection.extend {

  # Store the snippets locally.
  storage:
    name: 'Snippets'
    type: 'local'

  # Model class contained by this collection.
  model: Snippet

  # Sort snippets based on the `host` attribute.
  comparator: 'host'

  # List the snippets that are associated with a mode under the group witht the given `name`.
  group: (name) ->
    Snippets.group @, name

}, {

  # Retrieve **all** `Snippet` models.
  fetch: (callback) ->
    Snippet.populateModeGroups ->
      collection = new Snippets
      collection.fetch().then ->
        callback collection

  # Map the specified `snippets` based on their mode groups.
  #
  # Optionally, when a group `name` is provided, only a list of the snippets that are associated
  # with a mode under that group will be returned.
  group: (snippets, name) ->
    if name
      snippets.filter (snippet) ->
        snippet.inGroup name
    else
      groups = {}

      for name, modes of Snippet.modeGroups
        groups[name] = snippets.filter (snippet) ->
          snippet.inGroup name

      groups

}
