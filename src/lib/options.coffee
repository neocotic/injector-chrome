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

# Editor
# ------

# TODO: Document
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

    @model.save(code: @options.ace.getValue()).then ->
      $btn.html(i18n.get 'update_button_alt').delay(800).queue ->
        $btn.html(i18n.get 'update_button').dequeue()

  update: (@model) ->
    action = if @model? then 'removeClass' else 'addClass'
    @$('#reset_button, #update_button')[action] 'disabled'

# TODO: Document
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

    @model.save { mode }, wait: yes if @model?

# TODO: Document
# TODO: Add view for more advanced editor settings
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

    @listenTo @model, 'change:indentSize', @render
    @listenTo @model, 'change:lineWrap',   @render
    @listenTo @model, 'change:softTabs',   @render
    @listenTo @model, 'change:theme',      @render

  render: ->
    indentSize = @model.get 'indentSize'
    lineWrap   = @model.get 'lineWrap'
    softTabs   = @model.get 'softTabs'
    theme      = @model.get 'theme'

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

    @model.save
      indentSize: parseInt $indentSize.val(), 0
      lineWrap:   $lineWrap.val() is 'true'
      softTabs:   $softTabs.val() is 'true'
      theme:      $theme.val()

# TODO: Document
EditorView = Backbone.View.extend

  el: '#editor'

  initialize: ->
    @ace = ace.edit 'editor'
    @ace.setShowPrintMargin no
    @ace.getSession().on 'change', =>
      @model.trigger 'modified', @ace.getValue(), @hasUnsavedChanges() if @model?

    @settings = new EditorSettings { model: @options.settings }
    @controls = new EditorControls { @ace }
    @modes    = new EditorModes    { @ace }

    @listenTo @options.settings, """
      change:indentSize
      change:lineWrap
      change:softTabs
      change:theme
    """.replace(/\n/g, ' '), @updateSettings

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

# TODO: Document
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

    @model.save { analytics: $analytics.is ':checked' }, wait: yes

  updateAnalytics: ->
    action = if @model.get 'analytics' then 'init' else 'remove'
    do analytics[action]

# TODO: Document
SettingsView = Backbone.View.extend

  el: 'body'

  initialize: ->
    @general = new GeneralSettingsView { @model }

  render: ->
    @general.render()

    this

# Scripts
# -------

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
          mode: base.get('mode') or Script.defaultMode
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
        options.update()
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
      options.update()
    else unless @$el.hasClass 'active'
      @$el.addClass('active').siblings().removeClass 'active modified'
      options.update @model

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
      models.fetch (result) =>
        { settings, editorSettings, scripts } = result

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
        chrome.storage.onChanged.addListener (changes, areaName) ->
          console.log "[#{areaName}] Changed:"
          console.dir changes

  # TODO: Document
  update: (script) ->
    @editor.update script
    @scripts.update script

# Initialize `options` when the DOM is ready.
$ -> options.init()
