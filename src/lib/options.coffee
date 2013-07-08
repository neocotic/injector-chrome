# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# TODO: Capture more analytics

# Extract the models and collections that are required by the options page.
{ EditorSettings, EditorSettings, Script, Scripts } = models

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
      tab_position:  'middle-left'
      tab_inverted:  yes
    }
  ]

  # Ensure that the widget isn't loaded again.
  feedbackAdded = yes

# Editor
# ------

# View containing buttons for saving/resetting the code of the active script from the contents of
# the Ace editor.
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
    $btn = $ e.currentTarget
    return if $btn.hasClass('disabled') or not @model?

    code = @options.ace.getValue()

    @model.save({ code }).then =>
      @model.trigger 'modified', no, code

      $btn.html(i18n.get 'update_button_alt').delay(800).queue ->
        $btn.html(i18n.get 'update_button').dequeue()

  update: (@model) ->
    action = if @model? then 'removeClass' else 'addClass'
    @$('#reset_button, #update_button')[action] 'disabled'

# A selection of available modes/languages that are supported by this extension for executing
# scripts.
EditorModes = Backbone.View.extend

  el: '#editor_modes'

  template: _.template '<option value="<%- value %>"><%= html %></option>'

  events:
    'change': 'updateMode'

  render: ->
    _(options.config.editor.modes).each (mode) =>
      @$el.append @template
        html:  i18n.get "editor_mode_#{mode}"
        value: mode
    do @update

    this

  update: (@model) ->
    mode   = if @model? then @model.get 'mode'
    mode or= Script.defaultMode

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
    group = @$ '#editor_indent_size optgroup'
    _(options.config.editor.indentSizes).each (size) =>
      group.append @template
        html:  size
        value: size

    group = @$ '#editor_theme optgroup'
    _(options.config.editor.themes).each (theme) =>
      group.append @template
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

# Contains the Ace editor that allows the user to modify a script's code.
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
    action = if @model.get 'analytics' then 'add' else 'remove'
    analytics[action] options.config.analytics

# Parent view for all configurable settings.
SettingsView = Backbone.View.extend

  el: 'body'

  initialize: ->
    @general = new GeneralSettingsView { @model }

  render: ->
    @general.render()

    this

# Scripts
# -------

# View contains buttons used to control/manage the user's scripts.
ScriptControls = Backbone.View.extend

  el: '#scripts_controls'

  template: _.template """
    <form class="form-inline" id="<%- id %>">
      <div class="control-group">
        <%= html %>
      </div>
    </form>
  """

  events:
    'click #add_button':    'togglePrompt'
    'shown #add_button':    'promptAdd'
    'click #edit_button':   'togglePrompt'
    'shown #edit_button':   'promptEdit'
    'click #clone_button':  'togglePrompt'
    'shown #clone_button':  'promptClone'
    'click #delete_button': 'togglePrompt'
    'shown #delete_button': 'promptDelete'

  initialize: ->
    @$('#add_button, #clone_button, #edit_button').popover
      container: 'body'
      html:      yes
      placement: 'bottom'
      trigger:   'manual'
      content:   @template
        html: '<input type="text" spellcheck="false" placeholder="yourdomain.com">'
        id:   'edit_script'

    @$('#delete_button').popover
      container: 'body'
      html:      yes
      placement: 'bottom'
      trigger:   'manual'
      content:   @template
        html: """
          <p>#{i18n.get 'delete_confirm_text'}</p>
          <div style="text-align: right">
            <div class="btn-group">
              <button class="btn btn-mini" id="delete_cancel_button">#{i18n.get 'delete_cancel_button'}</button>
              <button class="btn btn-mini" id="delete_confirm_button">#{i18n.get 'delete_confirm_button'}</button>
            </div>
          </div>
        """
        id:   'remove_script'

  promptAdd: (e) ->
    @promptDomain e

  promptClone: (e) ->
    return if not @model?

    @promptDomain e, clone: yes

  promptDelete: ->
    return if not @model?

    $btn = @$ '#delete_button'

    $('#remove_script').on('submit', (e) =>
      false
    ).find(':button').first().focus()

    $('#delete_cancel_button').on 'click', ->
      $btn.popover 'hide'

    $('#delete_confirm_button').on 'click', =>
      @model.destroy().then ->
        options.update()
      $btn.popover 'hide'

  promptDomain: (e, options = {}) ->
    $btn  = $ e.currentTarget
    value = if options.clone or options.edit then @model.get 'host' else ''

    $('#edit_script').on('submit', (e) =>
      e.preventDefault()
      $form = $ e.target
      group = $form.find '.control-group'
      host  = $form.find(':text').val().replace /\s+/g, ''

      if not host
        group.addClass 'error'
      else
        group.removeClass 'error'

        if options.edit
          @model.save { host }
        else
          base = if options.clone then @model else new Script

          @collection.create {
            host
            code: base.get('code') or ''
            mode: base.get('mode') or Script.defaultMode
          }, {
            # TODO: Is `wait` necessary?
            wait: yes
            success: ->
              # TODO: Make new script active in editor
          }

      $btn.popover 'hide'

      false
    ).find(':input').focus().val value

  promptEdit: (e) ->
    return if not @model?

    @promptDomain e, edit: yes

  togglePrompt: (e) ->
    $btn = $ e.currentTarget
    $btn.popover 'toggle' unless $btn.hasClass 'disabled'

  update: (@model) ->
    @$('#add_button').removeClass 'disabled'

    if @model?
      @$('#clone_button, #delete_button, #edit_button').removeClass 'disabled'
    else
      @$('#clone_button, #delete_button, #edit_button').addClass('disabled').popover 'hide'

# Menu item which, when selected, makes the underlying script *active*, enabling the user to manage
# it and modify it's code.
ScriptItem = Backbone.View.extend

  tagName: 'li'

  template: _.template '<a><%= host %></a>'

  events:
    'click a': 'activate'

  initialize: ->
    @listenTo @model, 'change', @render
    @listenTo @model, 'destroy', @remove
    @listenTo @model, 'modified', @modified

  activate: (e) ->
    # TODO: Warn if another script is already active and it's code has unsaved changes
    if e.ctrlKey
      @$el.removeClass 'active modified'
      options.update()
    else unless @$el.hasClass 'active'
      @$el.addClass('active').siblings().removeClass 'active modified'
      options.update @model

  modified: (changed) ->
    action = if changed then 'addClass' else 'removeClass'
    @$el[action] 'modified'

  render: ->
    @$el.html @template @model.attributes

    this

# A menu of scripts that allows the user to easily manage them.
ScriptsList = Backbone.View.extend

  tagName: 'ul'

  className: 'nav nav-pills nav-stacked'

  addOne: (model) ->
    @$el.append new ScriptItem({ model }).render().$el

  addAll: ->
    @collection.each @addOne, this

  initialize: ->
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'reset', @addAll

  render: ->
    do @addAll

    this

# The primary view for managing scripts.
ScriptsView = Backbone.View.extend

  el: '#scripts_tab'

  initialize: ->
    @controls = new ScriptControls { @collection }
    @list     = new ScriptsList { @collection }

  render: ->
    @controls.render()
    @$('#scripts_nav').append @list.render().$el

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
      container: $this.attr('data-container') ? 'body'
      placement: $this.attr('data-placement') ? 'top'

# Options page setup
# ------------------

options = window.options = new class Options

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
    $.getJSON chrome.extension.getURL('configuration.json'), (@config) =>
      # Add the user feedback feature to the page.
      loadFeedback @config.options.userVoice

      # Begin initialization.
      i18n.traverse()

      # Retrieve all singleton instances as well as the collection for user-created scripts.
      models.fetch (result) =>
        { settings, editorSettings, scripts } = result

        # Create views for the important models and collections.
        @editor   = new EditorView(settings: editorSettings).render()
        @settings = new SettingsView(model: settings).render()
        @scripts  = new ScriptsView(collection: scripts).render()
        @scripts.update()

        # Ensure the current year is displayed throughout, where appropriate.
        $('.year-repl').html "#{new Date().getFullYear()}"

        # Bind tab selection event to all tabs.
        initialTabChange = yes
        $('a[data-tabify]').on 'click', ->
          target = $(this).data 'tabify'
          nav    = $ "#navigation a[data-tabify='#{target}']"
          parent = nav.parent 'li'

          unless parent.hasClass 'active'
            parent.addClass('active').siblings().removeClass 'active'
            $(target).show().siblings('.tab').hide()

            id = nav.attr 'id'
            settings.save(activeTab: id).then ->
              unless initialTabChange
                id = _.capitalize id.match(/(\S*)_nav$/)[1]
                analytics.track 'Tabs', 'Changed', id

              initialTabChange = no
              $(document.body).scrollTop 0

        # Reflect the previously persisted tab initially.
        $("##{settings.get 'activeTab'}").trigger 'click'

        # Ensure that form submissions don't reload the page.
        $('form:not([target="_blank"])').on 'submit', -> false

        # Ensure that popovers are closed when the Esc key is pressed anywhere.
        $(document).on 'keydown', (e) ->
          $('.js-popover-toggle').popover 'hide' if e.keyCode is 27

        # Support *goto* navigation elements that change the current scroll position when clicked.
        $('[data-goto]').on 'click', ->
          switch $(this).data 'goto'
            when 'top' then $(document.body).scrollTop 0

        # Bind analytical tracking events to key footer buttons and links.
        $('footer a[href*="neocotic.com"]').on 'click', ->
          analytics.track 'Footer', 'Clicked', 'Homepage'

        # Setup and configure the donation button in the footer.
        $('#donation input[name="hosted_button_id"]').val @config.options.payPal
        $('#donation').on 'submit', ->
          $(this).find(':submit').tooltip 'hide'

          analytics.track 'Footer', 'Clicked', 'Donate'

        do activateTooltips

  # Update the primary views with the active `script` provided.
  update: (script) ->
    @editor.update script
    @scripts.update script

# Initialize `options` when the DOM is ready.
$ -> options.init()
