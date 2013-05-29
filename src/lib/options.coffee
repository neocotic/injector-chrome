# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Feedback
# --------

# Indicate whether or not the user feedback feature has been added to the page.
feedbackAdded = no

# Add the user feedback feature to the page.
loadFeedback = ->
  # Only load and configure the feedback widget once.
  return if feedbackAdded

  { id, forum } = options.config.options.userVoice

  # Create a script element to load the UserVoice widget.
  uv       = document.createElement 'script'
  uv.async = 'async'
  uv.src   = "https://widget.uservoice.com/#{id}.js"
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
      forum_id:      forum
      tab_label:     i18n.get 'feedback_button'
      tab_color:     '#333'
      tab_position:  'middle-left'
      tab_inverted:  yes
    }
  ]

  # Ensure that the widget isn't loaded again.
  feedbackAdded = yes

# Settings
# --------

# TODO: Document
Settings = Backbone.Model.extend

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

# TODO: Document
EditorSettingsView = Backbone.View.extend

  el: '#editor_settings'

  events:
    'change #editorIndentSize': 'update'
    'change #editorLineWrap':   'update'
    'change #editorSoftTabs':   'update'
    'change #editorTheme':      'update'

  initialize: ->
    group = @$ '#editorIndentSize optgroup'
    _(options.config.editor.indentSizes).each (size) =>
      group.append @$ '<option/>', text: size

    # TODO: Comment
    group = @$ '#editorTheme optgroup'
    _(options.config.editor.themes).each (theme) =>
      group.append @$ '<option/>',
        html:  i18n.get "editor_theme_#{theme}"
        value: theme

    @listenTo @model, 'change:editorIndentSize', @render
    @listenTo @model, 'change:editorLineWrap',   @render
    @listenTo @model, 'change:editorSoftTabs',   @render
    @listenTo @model, 'change:editorTheme',      @render

  render: ->
    @$('#editorIndentSize').val @model.get 'editorIndentSize'
    @$('#editorLineWrap').val   @model.get 'editorLineWrap'
    @$('#editorSoftTabs').val   @model.get 'editorSoftTabs'
    @$('#editorTheme').val      @model.get 'editorTheme'

    this

  update: ->
    $indentSize = @$ '#editorIndentSize'
    $lineWrap   = @$ '#editorLineWrap'
    $softTabs   = @$ '#editorSoftTabs'
    $theme      = @$ '#editorTheme'

    @model.set
      editorIndentSize: parseInt $indentSize.val(), 0
      editorLineWrap:   $lineWrap.val() is 'true'
      editorSoftTabs:   $softTabs.val() is 'true'
      editorTheme:      $theme.val()
    # TODO: Sync

# TODO: Document
GeneralSettingsView = Backbone.View.extend

  el: '#general_tab'

  events:
    'change #analytics': 'update'

  initialize: ->
    @listenTo @model, 'change:analytics', @render

  render: ->
    @$('#analytics').prop 'checked', @model.get 'analytics'

    this

  update: ->
    $analytics = @$ '#analytics'

    @model.set analytics: $analytics.is ':checked'
    # TODO: Sync

# TODO: Document
SettingsView = Backbone.View.extend

  el: 'body'

  initialize: ->
    @model = new Settings

    @editor  = new EditorSettingsView  { @model }
    @general = new GeneralSettingsView { @model }

  render: ->
    @editor.render()
    @general.render()

    this

# Scripts
# -------

# TODO: Document
DEFAULT_MODE = 'javascript'

# TODO: Document
Script = Backbone.Model.extend

  defaults:
    code:   ''
    mode:   DEFAULT_MODE

  validate: (attributes) ->
    { id, mode } = attributes

    unless id
      'id is required'
    else unless mode
      'mode is required'
    else unless _(options.config.editor.modes).contains mode
      'mode is unrecognized'

# TODO: Document
Scripts = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'Scripts', 'local'

  model: Script

# TODO: Document
ScriptControls = Backbone.View.extend

  el: '#scripts_controls'

  events:
    'click #add_button': 'togglePrompt'
    'shown #add_button': 'promptAdd'
    'click #clone_button': 'togglePrompt'
    'shown #clone_button': 'promptClone'
    'click #delete_button': 'togglePrompt'
    'shown #delete_button': 'promptDelete'

  initialize: ->
    @$('#add_button, #clone_button').popover
      html:      yes
      placement: 'bottom'
      trigger:   'manual'
      content:   """
        <form class="form-inline" id="new_script">
          <div class="control-group">
            <input type="text" placeholder="yourdomain.com">
          </div>
        </form>
      """

    # TODO: Setup popover for delete button

  promptAdd: (e) ->
    @promptCreate $ e.target

  promptClone: (e) ->
    return if not @model?

    @promptCreate $(e.target), yes

  promptCreate: ($btn, clone) ->
    view = this

    $('#new_script').on('submit', ->
      $form  = $ this
      group  = $form.find '.control-group'
      id     = $form.find(':text').val().replace /\s+/g, ''
      exists = _(view.collection.pluck 'id').contains id

      if not id or exists
        group.addClass 'error'
      else
        group.removeClass 'error'

        base = if clone and view.model? then view.model else new Script

        view.collection.add new Script {
          id
          code: base.get('code') or ''
          mode: base.get('mode') or DEFAULT_MODE
        }, silent: yes
        # TODO: Sync data (is async?)
        # TODO: Make new script active in editor
        $btn.popover 'hide'

      false
    ).find(':text').focus().on 'keydown', (e) ->
      $btn.popover 'hide' if e.keyCode is 27

  promptDelete: ->
    # TODO: Complete
    return if not @model?

    # TODO: Prompt user to confirm action
    @model.destroy()
    # TODO: Is async?
    options.app.update()

  togglePrompt: (e) ->
    $btn = $ e.target
    $btn.popover 'toggle' unless $btn.is '.disabled'

  update: (@model) ->
    if @model?
      @$('#clone_button, #delete_button').removeClass 'disabled'
    else
      @$('#clone_button, #delete_button').addClass('disabled').popover 'hide'

# TODO: Document
ScriptEditor = Backbone.View.extend

  el: '#editor'

  initialize: ->
    @ace = ace.edit 'editor'
    @ace.setReadOnly yes
    @ace.setShowPrintMargin no

    @modes = new ScriptEditorModes { @ace }

    do @updateSettings

  render: ->
    @modes.render()

    this

  update: (@model) ->
    @ace.setValue @model?.get('code') or ''
    @modes.update @model

  updateSettings: ->
    settings = options.settings.model

    @ace.getSession().editorLineWrap settings.get 'editorLineWrap'
    @ace.getSession().setUseSoftTabs settings.get 'editorSoftTabs'
    @ace.getSession().setTabSize     settings.get 'editorIndentSize'
    @ace.setTheme "ace/theme/#{settings.get 'editorTheme'}"

# TODO: Document
ScriptEditorModes = Backbone.View.extend

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
    mode or= DEFAULT_MODE

    @$("option[value='#{mode}']").prop 'selected', yes
    do @updateMode

  updateMode: ->
    mode = @$el.val()

    @ace.getSession().setMode "ace/mode/#{mode}"

    if @model?
      @model.set { mode }
      # TODO: Sync?

# TODO: Document
ScriptItem = Backbone.View.extend

  tagName: 'li'

  template: _.template '<a><%= id %></a>'

  events:
    'click a': 'activate'

  activate: (e) ->
    if e.ctrlKey
      @$el.removeClass 'active'
      options.app.update()
    else
      @$el.addClass('active').siblings().removeClass 'active'
      options.app.update @model

  initialize: ->
    @listenTo @model, 'destroy', @remove
    @listenTo @model, 'change:id', @render

  render: ->
    @$el.html @template @model.attributes

    this

# TODO: Document
ScriptsList = Backbone.View.extend

  tagName: 'ul'

  className: 'nav nav-pills nav-stacked'

  addOne: (model) ->
    @$el.append new ScriptItem({ model }).render().$el

  addAll: ->
    _(@collection).each @addOne, this

  initialize: ->
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'reset', @addAll
    @listenTo @collection, 'change', @render
    @listenTo @collection, 'destroy', @remove

  render: ->
    # TODO: Is `ul` tag generated and appended automatically?
    do @addAll

    this

# TODO: Documnet
ScriptsView = Backbone.View.extend

  el: '#scripts_tab'

  initialize: ->
    @collection = new Scripts

    @controls = new ScriptControls { @collection }
    @editor   = new ScriptEditor
    @list     = new ScriptsList { @collection }

  render: ->
    @$('#scripts_nav').append @list.render().$el

    this

  update: (model) ->
    @controls.update model
    @editor.update model

# User interface
# --------------

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

options = window.options = new class Options extends utils.Class

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
    $.getJSON utils.url('configuration.json'), (@config) =>
      # Add the user feedback feature to the page.
      do loadFeedback

      # TODO: Comment
      @settings = new SettingsView().render()
      @app      = new ScriptsView().render()

      # Begin initialization.
      i18n.traverse()

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
          options.settings.model.set 'activeTag', id
          # TODO: Sync
          unless initialTabChange
            id = utils.capitalize id.match(/(\S*)_nav$/)[1]
            analytics.track 'Tabs', 'Changed', id

          initialTabChange = no
          $(document.body).scrollTop 0

      # Reflect the previously persisted tab initially.
      $("##{@settings.model.get 'activeTab'}").trigger 'click'

      # Ensure that form submissions don't reload the page.
      $('form:not([target="_blank"])').on 'submit', ->
        # Return `false` to ensure default behaviour is prevented.
        false

      # Bind analytical tracking events to key footer buttons and links.
      $('footer a[href*="neocotic.com"]').on 'click', ->
        analytics.track 'Footer', 'Clicked', 'Homepage'

      # Setup and configure the donation button in the footer.
      $('#donation input[name="hosted_button_id"]').val @config.options.payPal
      $('#donation').on 'submit', ->
        analytics.track 'Footer', 'Clicked', 'Donate'

      do activateTooltips

      # TODO: Remove debug
      for area in ['local', 'sync']
        store[area].onChanged '*', (name, newValue, oldValue) ->
          newValue = JSON.stringify newValue if _.isObject newValue
          oldValue = JSON.stringify oldValue if _.isObject oldValue
          console.log "#{name} setting has been changed in #{area} from '#{oldValue}' to '#{newValue}'"

# Initialize `options` when the DOM is ready.
$ -> options.init()
