# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# TODO: Add import/export functionality

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
# TODO: Add section for advanced editor settings
# TODO: Move editor settings into separate model
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
SettingsLookup = Backbone.Collection.extend

  chromeStorage: new Backbone.ChromeStorage 'Settings', 'sync'

  model: Settings

# TODO: Document
EditorSettingsView = Backbone.View.extend

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

    @listenTo @model, 'change:editorIndentSize', @render
    @listenTo @model, 'change:editorLineWrap',   @render
    @listenTo @model, 'change:editorSoftTabs',   @render
    @listenTo @model, 'change:editorTheme',      @render

  render: ->
    indentSize = @model.get 'editorIndentSize'
    lineWrap   = @model.get 'editorLineWrap'
    softTabs   = @model.get 'editorSoftTabs'
    theme      = @model.get 'editorTheme'

    @$("""
      #editor_indent_size option[value='#{indentSize}']
      #editor_line_wrap   option[value='#{lineWrap}']
      #editor_soft_tabs   option[value='#{softTabs}']
      #editor_theme       option[value='#{theme}']
    """.replace /\n/g, ', ').prop 'selected', yes

    this

  update: ->
    $indentSize = @$ '#editor_indent_size'
    $lineWrap   = @$ '#editor_line_wrap'
    $softTabs   = @$ '#editor_soft_tabs'
    $theme      = @$ '#editor_theme'

    @model.save {
      editorIndentSize: parseInt $indentSize.val(), 0
      editorLineWrap:   $lineWrap.val() is 'true'
      editorSoftTabs:   $softTabs.val() is 'true'
      editorTheme:      $theme.val()
    }, wait: yes

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

    @model.save { analytics: $analytics.is ':checked' }, wait: yes

# TODO: Document
SettingsView = Backbone.View.extend

  el: 'body'

  initialize: ->
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
    code: ''
    mode: DEFAULT_MODE

  validate: (attributes) ->
    { host, mode } = attributes

    unless host
      'host is required'
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
    'click #clone_button':  'togglePrompt'
    'shown #clone_button':  'promptClone'
    'click #delete_button': 'togglePrompt'
    'shown #delete_button': 'promptDelete'

  initialize: ->
    @$('#add_button, #clone_button').popover
      container: 'body'
      html:      yes
      placement: 'bottom'
      trigger:   'manual'
      content:   @template
        html: '<input type="text" placeholder="yourdomain.com">'
        id:   'new_script'

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
              <a class="btn btn-mini" id="delete_cancel_button">#{i18n.get 'delete_cancel_button'}</a>
              <a class="btn btn-mini" id="delete_confirm_button">#{i18n.get 'delete_confirm_button'}</a>
            </div>
          </div>
        """
        id:   'remove_script'

  promptAdd: (e) ->
    @promptCreate $ e.currentTarget

  promptClone: (e) ->
    return if not @model?

    @promptCreate $(e.currentTarget), yes

  promptCreate: ($btn, clone) ->
    $('#new_script').on('submit', (e) =>
      $form  = $ e.target
      group  = $form.find '.control-group'
      host   = $form.find(':text').val().replace /\s+/g, ''
      exists = _(@collection.pluck 'host').contains host

      if not host or exists
        group.addClass 'error'
      else
        group.removeClass 'error'

        base = if clone and @model? then @model else new Script

        console.dir @collection.create {
          host
          code: base.get('code') or ''
          mode: base.get('mode') or DEFAULT_MODE
        }, {
          wait: yes
          success: ->
            # TODO: Make new script active in editor
        }
        $btn.popover 'hide'

      false
    ).find(':text').focus()

  promptDelete: ->
    return if not @model?

    $btn = @$ '#delete_button'

    $('#remove_script :button').first().focus()

    $('#delete_cancel_button').on 'click', ->
      $btn.popover 'hide'

    $('#delete_confirm_button').on 'click', =>
      @model.destroy().then ->
        options.app.update()
      $btn.popover 'hide'

  togglePrompt: (e) ->
    $btn = $ e.currentTarget
    $btn.popover 'toggle' unless $btn.hasClass 'disabled'

  update: (@model) ->
    @$('#add_button').removeClass 'disabled'

    if @model?
      @$('#clone_button, #delete_button').removeClass 'disabled'
    else
      @$('#clone_button, #delete_button').addClass('disabled').popover 'hide'

# TODO: Document
ScriptEditor = Backbone.View.extend

  el: '#editor'

  initialize: ->
    @ace = ace.edit 'editor'
    @ace.setShowPrintMargin no
    @ace.getSession().on 'change', =>
      @model.trigger 'modified', @ace.getValue(), @hasUnsavedChanges() if @model?

    @controls = new ScriptEditorControls { @ace }
    @modes    = new ScriptEditorModes { @ace }

    do @updateSettings

  hasUnsavedChanges: ->
    @model? and @model.get('code') isnt @ace.getValue()

  render: ->
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
    settings = options.settings.model

    @ace.getSession().setUseWrapMode settings.get 'editorLineWrap'
    @ace.getSession().setUseSoftTabs settings.get 'editorSoftTabs'
    @ace.getSession().setTabSize     settings.get 'editorIndentSize'
    @ace.setTheme "ace/theme/#{settings.get 'editorTheme'}"

# TODO: Document
ScriptEditorControls = Backbone.View.extend

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

    @model.save(code: @options.ace.getValue()).then ->
      $btn.html(i18n.get 'update_button_alt').delay(800).queue ->
        $btn.html(i18n.get 'update_button').dequeue()

  update: (@model) ->
    action = if @model? then 'removeClass' else 'addClass'
    @$('#reset_button, #update_button')[action] 'disabled'

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

    @options.ace.getSession().setMode "ace/mode/#{mode}"

    @model.save { mode }, wait: yes if @model?

# TODO: Document
ScriptItem = Backbone.View.extend

  tagName: 'li'

  template: _.template '<a><%= host %></a>'

  events:
    'click a': 'activate'

  initialize: ->
    @listenTo @model, 'destroy', @remove
    @listenTo @model, 'modified', @modified

  activate: (e) ->
    # TODO: Warn if another script is already active and it's code has unsaved changes
    if e.ctrlKey
      @$el.removeClass 'active modified'
      options.app.update()
    else unless @$el.hasClass 'active'
      @$el.addClass('active').siblings().removeClass 'active modified'
      options.app.update @model

  modified: (value, changed) ->
    action = if changed then 'addClass' else 'removeClass'
    @$el[action] 'modified'

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
    @collection.each @addOne, this

  initialize: ->
    @listenTo @collection, 'add', @addOne
    @listenTo @collection, 'reset', @addAll

  render: ->
    do @addAll

    this

# TODO: Documnet
ScriptsView = Backbone.View.extend

  el: '#scripts_tab'

  initialize: ->
    @controls = new ScriptControls { @collection }
    @editor   = new ScriptEditor
    @list     = new ScriptsList { @collection }

  render: ->
    @controls.render()
    @editor.render()
    @$('#scripts_nav').append @list.render().$el

    this

  update: (model) ->
    @controls.update model
    @editor.update model

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

      # Begin initialization.
      i18n.traverse()

      # TODO: Complete
      (lookup = new SettingsLookup).fetch().then =>
        lookup.add new Settings unless lookup.length

        settings  = lookup.first()
        @settings = new SettingsView(model: settings).render()

        (scripts = new Scripts).fetch().then( =>
          @app = new ScriptsView(collection: scripts).render()
          @app.update()
        ).then =>
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
                  id = utils.capitalize id.match(/(\S*)_nav$/)[1]
                  analytics.track 'Tabs', 'Changed', id

                initialTabChange = no
                $(document.body).scrollTop 0

          # Reflect the previously persisted tab initially.
          $("##{settings.get 'activeTab'}").trigger 'click'

          # Ensure that form submissions don't reload the page.
          $('form:not([target="_blank"])').on 'submit', ->
            # Return `false` to ensure default behaviour is prevented.
            false

          # Ensure that popovers are closed when the Esc key is pressed anywhere.
          $(document).on 'keydown', (e) ->
            $('.js-popover-toggle').popover 'hide' if e.keyCode is 27

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
