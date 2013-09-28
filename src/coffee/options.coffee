# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# TODO: Capture more analytics

# Extract the models and collections that are required by the options page.
{ EditorSettings, EditorSettings, Snippet, Snippets } = models

# Utilities
# ---------

# Extend `_` with our utility functions.
_.mixin

  # Transform the given string into title case.
  capitalize: (str) ->
    return str unless str

    str.replace /\w+/g, (word) ->
      word[0].toUpperCase() + word[1..].toLowerCase()

# Feedback
# --------

# Indicate whether the user feedback feature has been added to the page.
feedbackAdded = no

# Add the user feedback feature to the page using the `options` provided.
loadFeedback = (options) ->
  # Only load and configure the feedback widget once.
  return if feedbackAdded

  # Create a script element to load the UserVoice widget.
  uv       = document.createElement 'script'
  uv.async = 'async'
  uv.src   = "https://widget.uservoice.com/#{options.id}.js"

  # Insert the script element into the DOM.
  script = document.getElementsByTagName('script')[0]
  script.parentNode.insertBefore uv, script

  # Configure the widget as it's loading.
  UserVoice = window.UserVoice or= []
  UserVoice.push [
    'showTab'
    'classic_widget'
    {
      mode:          'full'
      primary_color: '#333'
      link_color:    '#08c'
      default_mode:  'feedback'
      forum_id:      options.forum
      tab_label:     i18n.get 'feedback_button'
      tab_color:     '#333'
      tab_position:  'middle-right'
      tab_inverted:  yes
    }
  ]

  # Ensure that the widget isn't loaded again.
  feedbackAdded = yes

# Editor
# ------

# View containing buttons for saving/resetting the code of the selected snippet from the contents
# of the Ace editor.
EditorControls = Backbone.View.extend

  el: '#editor_controls'

  events:
    'click #reset_button':  'reset'
    'click #update_button': 'save'

  render: ->
    do @update

    this

  reset: (e) ->
    return if $(e.currentTarget).hasClass('disabled') or not @model?

    @options.ace.setValue @model.get 'code'
    @options.ace.gotoLine 0

  save: (e) ->
    $button = $ e.currentTarget

    return if $button.hasClass('disabled') or not @model?

    code = @options.ace.getValue()

    @model.save({ code }).then =>
      @model.trigger 'modified', no, code

      $button.html(i18n.get 'update_button_alt').delay(800).queue ->
        $button.html(i18n.get 'update_button').dequeue()

  update: (@model) ->
    $buttons = @$ '#reset_button, #update_button'

    if @model?
      $buttons.removeClass 'disabled'
    else
      $buttons.addClass 'disabled'

# A selection of available modes/languages that are supported by this extension for injecting
# snippets.
EditorModes = Backbone.View.extend

  el: '#editor_modes'

  groupTemplate: _.template '<optgroup label="<%- label %>"></optgroup>'

  modeTemplate: _.template '<option value="<%- value %>"><%= html %></option>'

  events:
    'change': 'updateMode'

  render: ->
    _.each Snippet.modeGroups, (modes, name) =>
      $group = $ @groupTemplate
        label: i18n.get "editor_mode_group_#{name}"

      _.each modes, (mode) =>
        $group.append @modeTemplate
          html:  i18n.get "editor_mode_#{mode}"
          value: mode

      @$el.append $group

    do @update

    this

  update: (@model) ->
    mode   = if @model? then @model.get 'mode'
    mode or= Snippet.defaultMode

    @$("option[value='#{mode}']").prop 'selected', yes

    do @updateMode

  updateMode: ->
    mode = @$el.val()

    @options.ace.getSession().setMode "ace/mode/#{mode}"

    @model.save { mode } if @model?

# View containing options that allow the user to configure the Ace editor.
EditorSettings = Backbone.View.extend

  el: '#editor_settings'

  template: _.template '<option value="<%- value %>"><%= html %></option>'

  events:
    'change #editor_indent_size': 'update'
    'change #editor_line_wrap':   'update'
    'change #editor_soft_tabs':   'update'
    'change #editor_theme':       'update'

  initialize: ->
    $sizes = @$ '#editor_indent_size optgroup'
    _.each page.config.editor.indentSizes, (size) =>
      $sizes.append @template
        html:  size
        value: size

    $themes = @$ '#editor_theme optgroup'
    _.each page.config.editor.themes, (theme) =>
      $themes.append @template
        html:  i18n.get "editor_theme_#{theme}"
        value: theme

    @listenTo @model, """
      change:indentSize
      change:lineWrap
      change:softTabs
      change:theme
    """, @render

  render: ->
    indentSize = @model.get 'indentSize'
    lineWrap   = @model.get 'lineWrap'
    softTabs   = @model.get 'softTabs'
    theme      = @model.get 'theme'

    @$("""
      #editor_indent_size option[value='#{indentSize}'],
      #editor_line_wrap   option[value='#{lineWrap}'],
      #editor_soft_tabs   option[value='#{softTabs}'],
      #editor_theme       option[value='#{theme}']
    """).prop 'selected', yes

    this

  update: ->
    $indentSize = @$ '#editor_indent_size'
    $lineWrap   = @$ '#editor_line_wrap'
    $softTabs   = @$ '#editor_soft_tabs'
    $theme      = @$ '#editor_theme'

    @model.save
      indentSize: parseInt $indentSize.val(), 0
      lineWrap:   $lineWrap.val() is 'true'
      softTabs:   $softTabs.val() is 'true'
      theme:      $theme.val()

# Contains the Ace editor that allows the user to modify a snippet's code.
EditorView = Backbone.View.extend

  el: '#editor'

  initialize: ->
    @ace = ace.edit 'editor'
    @ace.setShowPrintMargin no
    @ace.getSession().on 'change', =>
      @model.trigger 'modified', @hasUnsavedChanges(), @ace.getValue() if @model?

    @settings = new EditorSettings { model: @options.settings }
    @controls = new EditorControls { @ace }
    @modes    = new EditorModes    { @ace }

    @listenTo @options.settings, """
      change:indentSize
      change:lineWrap
      change:softTabs
      change:theme
    """, @updateSettings

    do @updateSettings

  hasUnsavedChanges: ->
    @model? and @model.get('code') isnt @ace.getValue()

  render: ->
    @settings.render()
    @controls.render()
    @modes.render()

    this

  update: (@model) ->
    @ace.setReadOnly not @model?
    @ace.setValue @model?.get('code') or ''
    @ace.gotoLine 0

    @controls.update @model
    @modes.update @model

  updateSettings: ->
    { settings } = @options

    @ace.getSession().setUseWrapMode settings.get 'lineWrap'
    @ace.getSession().setUseSoftTabs settings.get 'softTabs'
    @ace.getSession().setTabSize     settings.get 'indentSize'
    @ace.setTheme "ace/theme/#{settings.get 'theme'}"

# Settings
# --------

# Allows the user to modify the general settings of the extension.
GeneralSettingsView = Backbone.View.extend

  el: '#general_tab'

  events:
    'change #analytics': 'update'

  initialize: ->
    @listenTo @model, 'change:analytics', @render
    @listenTo @model, 'change:analytics', @updateAnalytics

    do @updateAnalytics

  render: ->
    @$('#analytics').prop 'checked', @model.get 'analytics'

    this

  update: ->
    $analytics = @$ '#analytics'

    @model.save { analytics: $analytics.is ':checked' }

  updateAnalytics: ->
    if @model.get 'analytics'
      analytics.add page.config.analytics
    else
      analytics.remove()

# Parent view for all configurable settings.
SettingsView = Backbone.View.extend

  el: 'body'

  initialize: ->
    @general = new GeneralSettingsView { @model }

  render: ->
    @general.render()

    this

# Snippets
# --------

# View contains buttons used to control/manage the user's snippets.
SnippetControls = Backbone.View.extend

  el: '#snippets_controls'

  events:
    'show.bs.popover .btn':           'closeOtherPrompts'
    'click #delete_menu .btn':        'closeOtherPrompts'
    'click #add_button':              'togglePrompt'
    'shown.bs.popover #add_button':   'promptAdd'
    'click #edit_button':             'togglePrompt'
    'shown.bs.popover #edit_button':  'promptEdit'
    'click #clone_button':            'togglePrompt'
    'shown.bs.popover #clone_button': 'promptClone'
    'click #delete_menu .js-resolve': 'removeSnippet'

  initialize: ->
    @$('#add_button, #clone_button, #edit_button').popover
      html:      yes
      trigger:   'manual'
      placement: 'bottom'
      container: 'body'
      content:   """
        <form id="edit_snippet" class="form-inline" role="form">
          <div class="form-group">
            <input type="text" class="form-control" spellcheck="false" placeholder="yourdomain.com">
          </div>
        </form>
      """

  closeOtherPrompts: (e) ->
    hidePopovers e.currentTarget

  promptAdd: ->
    do @promptHost

  promptClone: ->
    return if not @model?

    @promptHost clone: yes

  promptEdit: ->
    return if not @model?

    @promptHost edit: yes

  promptHost: (options = {}) ->
    $form = $ '#edit_snippet'
    value = if options.clone or options.edit then @model.get 'host' else ''

    $form.on 'submit', (e) =>
      $group = $form.find '.form-group'
      host   = $form.find(':text').val().replace /\s+/g, ''

      if not host
        $group.addClass 'has-error'
      else
        $group.removeClass 'has-error'

        if options.edit
          @model.save { host }
        else
          base = if options.clone then @model else new Snippet

          @collection.create {
            host
            code: base.get('code') or ''
            mode: base.get('mode') or Snippet.defaultMode
          }, success: (model) ->
            model.select()

            page.snippets.list.showSelected()

      do hidePopovers

      false

    $form.find(':text').focus().val value

  removeSnippet: ->
    return if not @model?

    model = @model
    model.deselect().done ->
      model.destroy()

  togglePrompt: (e) ->
    $button = $ e.currentTarget

    $button.popover 'toggle' unless $button.hasClass 'disabled'

  update: (@model) ->
    $modelButtons = @$ '#clone_button, #delete_menu .btn, #edit_button'

    @$('#add_button').removeClass 'disabled'

    if @model?
      $modelButtons.removeClass 'disabled'
    else
      $modelButtons.addClass 'disabled'

      do hidePopovers

# Menu item which, when selected, enables the user to manage and modify the code of the underlying
# snippet.
SnippetItem = Backbone.View.extend

  tagName: 'li'

  template: _.template '<a><%= host %></a>'

  events:
    'click a': 'toggleSelection'

  initialize: ->
    @listenTo @model, 'destroy', @remove
    @listenTo @model, 'modified', @modified
    @listenTo @model, 'change:host change:selected', @render

  modified: (changed) ->
    if changed
      @$el.addClass 'modified'
    else
      @$el.removeClass 'modified'

  render: ->
    @$el.html @template @model.attributes

    if @model.get 'selected'
      @$el.addClass 'active'
    else
      @$el.removeClass 'active modified'

    this

  toggleSelection: (e) ->
    if e.ctrlKey
      @model.deselect()
    else unless @$el.hasClass 'active'
      @model.select()

      page.snippets.list.showSelected()

# A menu of snippets that allows the user to easily manage them.
SnippetsList = Backbone.View.extend

  el: '#snippets_list'

  addOne: (model) ->
    @$el.append new SnippetItem({ model }).render().$el

  addAll: ->
    @collection.each @addOne, this

  initialize: ->
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'reset', @addAll

  render: ->
    do @addAll

    this

  # TODO: Fix as currently not working
  showSelected: ->
    $selectedItem = @$ 'li.active a'

    @$el.scrollTop $selectedItem.offset().top - @$el.offset().top

# The primary view for managing snippets.
SnippetsView = Backbone.View.extend

  el: '#snippets_tab'

  initialize: ->
    @controls = new SnippetControls { @collection }
    @list     = new SnippetsList { @collection }

  render: ->
    @controls.render()
    @list.render()

    this

  update: (model) ->
    @controls.update model

# Miscellaneous
# -------------

# Activate tooltip effects, optionally only within a specific context.
activateTooltips = (selector) ->
  base = $ selector or document

  # Reset all previously treated tooltips.
  base.find('[data-original-title]').each ->
    $this = $ this

    $this.tooltip 'destroy'
    $this.attr 'title', $this.attr 'data-original-title'
    $this.removeAttr 'data-original-title'

  # Apply tooltips to all relevant elements.
  base.find('[title]').each ->
    $this = $ this

    $this.tooltip
      container: $this.attr('data-container') or 'body'
      placement: $this.attr('data-placement') or 'top'

# Hide all visibile popovers and remove them from the DOM with the option to exclude specific
# `exceptions`.
hidePopovers = (exceptions) ->
  $toggles = $ '.js-popover-toggle'
  $toggles = $toggles.not except if except?

  $toggles.popover 'hide'
  $('.popover').remove()

# Options page setup
# ------------------

page = window.page = new class Options

  # Create a new instance of `Options`.
  constructor: ->
    @config  = {}
    @version = ''

  # Public functions
  # ----------------

  # Initialize the options page.  
  # This will involve inserting and configuring the UI elements as well as loading the current
  # settings.
  init: ->
    # It's nice knowing what version is running.
    { @version } = chrome.runtime.getManifest()

    # Load the configuration data from the file before storing it locally.
    chrome.runtime.sendMessage { type: 'config' }, (@config) =>
      # Map the mode groups now to save the configuration data from being loaded again by
      # `Snippets.fetch`.
      Snippet.mapModeGroups @config.editor.modeGroups

      # Add the user feedback feature to the page.
      loadFeedback @config.options.userVoice

      # Begin initialization.
      i18n.traverse()

      # Retrieve all singleton instances as well as the collection for user-created snippets.
      models.fetch (result) =>
        { settings, editorSettings, snippets } = result

        # Create views for the important models and collections.
        @editor   = new EditorView(settings: editorSettings).render()
        @settings = new SettingsView(model: settings).render()
        @snippets = new SnippetsView(collection: snippets).render()

        # Ensure that views are updated accordingly when snippets are selected/deselected.
        snippets.on 'selected deselected', (snippet) =>
          if snippet.get 'selected' then @update snippet else do @update

        selectedSnippet = snippets.findWhere selected: yes
        if selectedSnippet
          @update selectedSnippet

          @snippets.list.showSelected()

        # Ensure the current year is displayed throughout, where appropriate.
        $('.js-insert-year').html "#{new Date().getFullYear()}"

        # Bind tab selection event to all tabs.
        initialTabChange = yes
        $('a[data-tabify]').on 'click', ->
          target = $(this).data 'tabify'
          nav    = $ "header.navbar .nav a[data-tabify='#{target}']"
          parent = nav.parent 'li'

          unless parent.hasClass 'active'
            parent.addClass('active').siblings().removeClass 'active'
            $(target).removeClass('hide').siblings('.tab').addClass 'hide'

            id = nav.attr 'id'
            settings.save(tab: id).then ->
              unless initialTabChange
                id = _.capitalize id.match(/(\S*)_nav$/)[1]
                analytics.track 'Tabs', 'Changed', id

              initialTabChange = no
              $(document.body).scrollTop 0

        # Reflect the previously persisted tab initially.
        $("##{settings.get 'tab'}").trigger 'click'

        # Ensure that form submissions don't reload the page.
        $('form:not([target="_blank"])').on 'submit', -> false

        # Ensure that popovers are closed when the `Esc` key is pressed anywhere.
        $(document).on 'keydown', (e) ->
          do hidePopovers if e.keyCode is 27

        # Support *goto* navigation elements that change the current scroll position when clicked.
        $('[data-goto]').on 'click', ->
          switch $(this).data 'goto'
            when 'top' then $(document.body).scrollTop 0

        # Bind analytical tracking events to key footer buttons and links.
        $('footer a[href*="neocotic.com"]').on 'click', ->
          analytics.track 'Footer', 'Clicked', 'Homepage'

        # Setup and configure donation buttons.
        $('#donation input[name="hosted_button_id"]').val @config.options.payPal
        $('.js-donate').on 'click', ->
          $(this).tooltip 'hide'

          $('#donation').submit()

          analytics.track 'Donate', 'Clicked'

        do activateTooltips

  # Update the primary views with the selected `snippet` provided.
  update: (snippet) ->
    @editor.update snippet
    @snippets.update snippet

# Initialize the `page` when the DOM is ready.
$ -> page.init()
