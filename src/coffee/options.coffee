# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Extract any models and collections that are required by the options page.
{Snippet} = models

# Feedback
# --------

# Indicate whether the user feedback feature has been added to the page.
feedbackAdded = no

# Add the user feedback feature to the page using the `options` provided.
loadFeedback = (options) ->
  # Only load and configure the feedback widget once.
  return if feedbackAdded

  # Create a script element to load the UserVoice widget.
  uv       = document.createElement('script')
  uv.async = yes
  uv.src   = "https://widget.uservoice.com/#{options.id}.js"

  # Insert the script element into the DOM.
  script = document.querySelector('script')
  script.parentNode.insertBefore(uv, script)

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
      tab_label:     i18n.get('feedback_button')
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
EditorControls = Injector.View.extend {

  # Overlay the editor controls on top of this element.
  el: '#editor_controls'

  # Register DOM events for the editor controls
  events:
    'click #reset_button:not(:disabled)':  'reset'
    'click #save_button:not(:disabled)': 'save'

  # Render the editor controls.
  render: ->
    @update()

    @

  # Reset the Ace editor so that it is empty.
  #
  # Nothing happens if there is no snippet selected.
  reset: ->
    return unless @hasModel()

    {ace} = @options

    ace.setValue(@model.get('code'))
    ace.gotoLine(0)

  # Save the contents of the Ace editor as the snippet code.
  save: (event) ->
    return unless @hasModel()

    $button = $(event.currentTarget)
    code    = @options.ace.getValue()

    $button.button('loading').delay(500)

    @model.save({ code })
    .then =>
      @model.trigger('modified', no, code)

      analytics.track('Snippet', 'Changed', 'Code')

      $button.queue ->
        $button.button('reset').dequeue()

  # Update the state of the editor controls.
  update: (@model) ->
    $buttons = @$('#reset_button, #save_button')

    # Ensure that specific buttons are only enabled when a snippet is selected.
    $buttons.prop('disabled', not @hasModel())

}

# A selection of available modes/languages that are supported by this extension for injecting
# snippets.
EditorModes = Injector.View.extend {

  # Overlay the editor modes on top of this element.
  el: '#editor_modes'

  # Template for mode group option groups.
  groupTemplate: _.template """
    <optgroup label="<%- ctx.label %>"></optgroup>
  """

  # Template for mode options.
  modeTemplate: _.template """
    <option value="<%- ctx.value %>"><%= ctx.html %></option>
  """

  # Register DOM events for the editor modes.
  events:
    'change': 'save'

  # Render the editor modes.
  render: ->
    for name, modes of Snippet.modeGroups
      do (name, modes) =>
        $group = $ @groupTemplate {
          label: i18n.get("editor_mode_group_#{name}")
        }

        for mode in modes
          $group.append @modeTemplate {
            html:  i18n.get("editor_mode_#{mode}")
            value: mode
          }

        @$el.append($group)

    @update()

    @

  # Save the selected mode as the snippet mode.
  save: ->
    mode = @$el.val()

    @options.ace.getSession().setMode("ace/mode/#{mode}")

    if @hasModel()
      analytics.track('Snippet', 'Changed', 'Mode')

      @model.save({ mode })

  # Update the state of the editor modes.
  update: (@model) ->
    mode   = @model?.get('mode')
    mode or= Snippet.defaultMode

    @$el.prop('disabled', not @hasModel())

    @$("option[value='#{mode}']").prop('selected', yes)

    @save()

}

# View containing options that allow the user to configure the Ace editor.
EditorSettingsView = Injector.View.extend {

  # Overlay the editor settings on top of this element.
  el: '#editor_settings'

  # Template for setting options.
  template: _.template """
    <option value="<%- ctx.value %>"><%= ctx.html %></option>
  """

  # Register DOM events for the editor settings.
  events:
    'change #editor_indent_size':       'update'
    'change #editor_line_wrap':         'update'
    'change #editor_soft_tabs':         'update'
    'change #editor_theme':             'update'
    'click .modal-footer .btn-warning': 'restoreDefaults'

  # Initialize the editor settings.
  init: ->
    $sizes  = @$('#editor_indent_size')
    $themes = @$('#editor_theme')

    for size in page.config.editor.indentSizes
      $sizes.append @template {
        html:  size
        value: size
      }

    for theme in page.config.editor.themes
      $themes.append @template {
        html:  i18n.get("editor_theme_#{theme}")
        value: theme
      }

    @listenTo(@model, 'change', @captureAnalytics)
    @listenTo(@model, 'change', @render)

  # Capture the analytics for any changed model attributes.
  captureAnalytics: ->
    attrs = @model.changedAttributes() or {}

    analytics.track('Editor', 'Changed', attr) for attr of attrs

  # Render the editor settings.
  render: ->
    indentSize = @model.get('indentSize')
    lineWrap   = @model.get('lineWrap')
    softTabs   = @model.get('softTabs')
    theme      = @model.get('theme')

    @$('#editor_indent_size').val("#{indentSize}")
    @$('#editor_line_wrap').val("#{lineWrap}")
    @$('#editor_soft_tabs').val("#{softTabs}")
    @$('#editor_theme').val(theme)

    @

  # Restore the attributes of underlying model to their default values.
  restoreDefaults: ->
    @model.restoreDefaults()
    @model.save()

  # Update the state of the editor settings.
  update: ->
    $indentSize = @$('#editor_indent_size')
    $lineWrap   = @$('#editor_line_wrap')
    $softTabs   = @$('#editor_soft_tabs')
    $theme      = @$('#editor_theme')

    @model.save
      indentSize: parseInt($indentSize.val(), 0)
      lineWrap:   $lineWrap.val() is 'true'
      softTabs:   $softTabs.val() is 'true'
      theme:      $theme.val()

}

# Contains the Ace editor that allows the user to modify a snippet's code.
EditorView = Injector.View.extend {

  # Overlay the editor on top of this element.
  el: '#editor'

  # Initialize the editor.
  init: ->
    @ace = ace.edit('editor')
    @ace.setReadOnly(not @hasModel())
    @ace.setShowPrintMargin(no)
    @ace.getSession().on 'change', =>
      @model.trigger('modified', @hasUnsavedChanges(), @ace.getValue()) if @hasModel()

    @settings = new EditorSettingsView({ model: @options.settings })
    @controls = new EditorControls({ @ace })
    @modes    = new EditorModes({ @ace })

    @listenTo(@options.settings, 'change', @updateEditor)

    @updateEditor()

  # Determine whether or not the contents of the Ace editor is different from the snippet code.
  hasUnsavedChanges: ->
    @ace.getValue() isnt @model?.get('code')

  # Render the editor.
  render: ->
    @settings.render()
    @controls.render()
    @modes.render()

    @

  # Update the state of the editor.
  update: (@model) ->
    @ace.setReadOnly(not @hasModel())
    @ace.setValue(@model?.get('code') or '')
    @ace.gotoLine(0)

    @settings.update(@model)
    @controls.update(@model)
    @modes.update(@model)

  # Update the Ace editor with the selected options.
  updateEditor: ->
    {settings} = @options
    aceSession = @ace.getSession()

    aceSession.setUseWrapMode(settings.get('lineWrap'))
    aceSession.setUseSoftTabs(settings.get('softTabs'))
    aceSession.setTabSize(settings.get('indentSize'))
    @ace.setTheme("ace/theme/#{settings.get('theme')}")

}

# Settings
# --------

# Allows the user to modify the general settings of the extension.
GeneralSettingsView = Injector.View.extend {

  # Overlay the general settings on top of this element.
  el: '#general_tab'

  # Register DOM events for the general settings.
  events:
    'change #analytics': 'save'

  # Initialize the general settings.
  init: ->
    @listenTo(@model, 'change:analytics', @render)
    @listenTo(@model, 'change:analytics', @updateAnalytics)

    @updateAnalytics()

  # Render the general settings.
  render: ->
    @$('#analytics').prop('checked', @model.get('analytics'))

    @

  # Save the settings.
  save: ->
    $analytics = @$('#analytics')

    @model.save({ analytics: $analytics.is(':checked') })

  # Add or remove analytics from the page depending on settings.
  updateAnalytics: ->
    if @model.get('analytics')
      analytics.add(page.config.analytics)
      analytics.track('General', 'Changed', 'Analytics', 1)
    else
      analytics.track('General', 'Changed', 'Analytics', 0)
      analytics.remove()

}

# Parent view for all configurable settings.
SettingsView = Injector.View.extend {

  # Overlay the settings on top of this element.
  el: 'body'

  # Initialize the settings.
  init: ->
    @general = new GeneralSettingsView({ @model })

  # Render the settings.
  render: ->
    @general.render()

    @

}

# Snippets
# --------

# View contains buttons used to control/manage the user's snippets.
SnippetControls = Injector.View.extend {

  # Overlay the snippet controls on top of this element.
  el: '#snippets_controls'

  # Register DOM events for the snippet controls.
  events:
    'click #delete_menu .js-resolve':                          'removeSnippet'
    'hide.bs.modal .modal':                                    'resetHost'
    'show.bs.modal #snippet_clone_modal, #snippet_edit_modal': 'insertHost'
    'shown.bs.modal .modal':                                   'focusHost'
    'submit #snippet_add_form':                                'addSnippet'
    'submit #snippet_clone_form':                              'cloneSnippet'
    'submit #snippet_edit_form':                               'editSnippet'

  # Handle the form submission to add a new snippet.
  addSnippet: (event) ->
    @submitSnippet(event, 'add')

  # Grant focus to the host field within the originating modal dialog.
  focusHost: (event) ->
    $modal = $(event.currentTarget)

    $modal.find('form :text').focus()

  # Handle the form submission to clone an existing snippet.
  cloneSnippet: (event) ->
    @submitSnippet(event, 'clone')

  # Handle the form submission to edit an existing snippet.
  editSnippet: (event) ->
    @submitSnippet(event, 'edit')

  # Insert the host attribute of the selected snippet in to the field within the originating modal
  # dialog.
  insertHost: (event) ->
    $modal = $(event.currentTarget)

    $modal.find('form :text').val(@model.get('host'))

  # Deselect and destroy the active snippet.
  removeSnippet: ->
    return unless @hasModel()

    {model} = @
    model.deselect().done ->
      model.destroy()

  # Reset the host field within the originating modal dialog.
  resetHost: (event) ->
    $modal = $(event.currentTarget)

    $modal.find('form :text').val('')

  # Handle the form submission to determine how the input should be stored based on the `action`.
  submitSnippet: (event, action) ->
    $form  = $(event.currentTarget)
    $group = $form.find('.form-group:first')
    $modal = $form.closest('.modal')
    host   = $group.find(':text').val().replace(/\s+/g, '')

    unless host
      $group.addClass('has-error')
    else
      $group.removeClass('has-error')

      $modal.modal('hide')

      if action is 'edit'
        @model.save({ host })
        .done ->
          analytics.track('Snippet', 'Renamed', host)

          page.snippets.list.sort()
      else
        base = if action is 'clone' then @model else new Snippet()

        @collection.create {
          host
          code: base.get('code') or ''
          mode: base.get('mode') or Snippet.defaultMode
        }, success: (model) ->
          if action is 'clone'
            analytics.track('Snippet', 'Cloned', base.get('host'))
          else
            analytics.track('Snippet', 'Created', host)

          model.select().done ->
            page.snippets.list.sort().showSelected()

    false

  # Update the state of the snippet controls.
  update: (@model) ->
    $modelButtons = @$('#clone_button, #edit_button, #delete_menu .btn')

    $modelButtons.prop('disabled', not @hasModel())

}

# Menu item which, when selected, enables the user to manage and modify the code of the underlying
# snippet.
SnippetItem = Injector.View.extend {

  # Tag name for the element to be created for the snippet item.
  tagName: 'li'

  # Prevent `activateTooltips` from interfering with the tooltip of the snippet item.
  className: 'js-tooltip-ignore'

  # Template for the snippet item.
  mainTemplate: _.template """
    <a>
      <span><%= ctx.host %></span>
    </a>
  """

  # Template for the tooltip of the snippet item.
  tooltipTemplate: _.template """
    <div class="snippet-tooltip">
      <span class="snippet-tooltip-host"><%= ctx.host %></span>
      <span class="snippet-tooltip-mode"><%= i18n.get('editor_mode_' + ctx.mode) %></span>
    </div>
  """

  # Register DOM events for the snippet item.
  events:
    'click a': 'updateSelection'

  # Initialize the snippet item.
  init: ->
    @listenTo(@model, 'destroy', @remove)
    @listenTo(@model, 'modified', @modified)
    @listenTo(@model, 'change:host change:selected', @render)
    @listenTo(@model, 'change:host change:mode', @updateTooltip)

    @updateTooltip()

  # Highlight that the snippet code has been modified in the editor.
  modified: (changed) ->
    if changed
      @$el.addClass('modified')
    else
      @$el.removeClass('modified')

  # Override `remove` to ensure that the tooltip is properly destroyed upon removal.
  remove: ->
    @$el.tooltip('destroy')

    @super('remove')

  # Render the snippet item.
  render: ->
    @$el.html(@mainTemplate(@model.pick('host')))

    if @model.get('selected')
      @$el.addClass('active')
    else
      @$el.removeClass('active modified')

    @

  # Update the selected state of the snippet depending on the given `event`.
  updateSelection: (event) ->
    if event.ctrlKey or event.metaKey and /^mac/i.test(navigator.platform)
      @model.deselect()
    else unless @$el.hasClass('active')
      @model.select()

  # Update the tooltip for the snippet item, destroying any previous tooltip in the process.
  updateTooltip: ->
    @$el
    .tooltip('destroy')
    .tooltip {
      container: 'body'
      html:      yes
      title:     @tooltipTemplate(@model.pick('host', 'mode'))
    }

}

# A menu of snippets that allows the user to easily manage them.
SnippetsList = Injector.View.extend {

  # Overlay the snippets list on top of this element.
  el: '#snippets_list'

  # Create and add a `SnippetItem` for the specified `model`.
  addItem: (model) ->
    item = new SnippetItem({ model })

    @items.push(item)

    @$el.append(item.render().$el)

    item

  # Initialize the snippets list.
  init: ->
    @items = []

    @listenTo(@collection, 'add', @addItem)
    @listenTo(@collection, 'reset', @resetItems)

  # Override `remove` to ensure that managed sub-views are removed as well.
  remove: ->
    @removeItems()

    @super('remove')

  # Remove all managed sub-views.
  removeItems: ->
    @items.shift().remove() while @items.length > 0

  # Render the snippets list.
  render: ->
    @resetItems()

    @

  # Remove any existing managed sub-views before creating and adding new `SnippetItem` views for
  # each snippet model in the collection.
  resetItems: ->
    @removeItems()

    @collection.each(@addItem, @)

  # Scroll to the selected snippet in the list.
  showSelected: ->
    $selectedItem = @$('li.active')

    @$el.scrollTop($selectedItem.offset().top - @$el.offset().top)

    @

  # Detach each snippet item in the list and sort them based on their text contents before
  # re-appending them.
  sort: ->
    @$el.append(_.sortBy(@$('li').detach(), 'textContent'))

    @

}

# The primary view for managing snippets.
SnippetsView = Injector.View.extend {

  # Overlay the snippets on top of this element.
  el: '#snippets_tab'

  # Initialize the snippets.
  init: ->
    @controls = new SnippetControls({ @collection })
    @list     = new SnippetsList({ @collection })

  # Render the snippets.
  render: ->
    @controls.render()
    @list.render()

    @

  # Update the state of the snippets.
  update: (model) ->
    @controls.update(model)

}

# Miscellaneous
# -------------

# Activate tooltip effects, optionally only within a specific context.
activateTooltips = (selector) ->
  base = $(selector or document)

  # Reset all previously treated tooltips.
  base.find('[data-original-title]:not(.js-tooltip-ignore)')
  .each ->
    $this = $(@)

    $this
    .tooltip('destroy')
    .attr('title', $this.attr 'data-original-title')
    .removeAttr('data-original-title')

  # Apply tooltips to all relevant elements.
  base.find('[title]:not(.js-tooltip-ignore)')
  .each ->
    $this = $(@)

    $this.tooltip {
      container: $this.attr('data-container') or 'body'
      placement: $this.attr('data-placement') or 'top'
    }

# Options page setup
# ------------------

# Responsible for managing the options page.
class OptionsPage

  # The current version of the extension.
  #
  # This will be updated with the actual value during the page's initialization.
  version: ''

  # Create a new instance of `OptionsPage`.
  constructor: ->
    @config = {}

  # Public functions
  # ----------------

  # Initialize the options page.
  #
  # This will involve inserting and configuring the UI elements as well as loading the current
  # settings.
  init: ->
    # It's nice knowing what version is running.
    {@version} = chrome.runtime.getManifest()

    # Load the configuration data from the file before storing it locally.
    chrome.runtime.sendMessage { type: 'config' }, (@config) =>
      # Map the mode groups now to save the configuration data from being loaded again by
      # `Snippets.fetch`.
      Snippet.mapModeGroups(@config.editor.modeGroups)

      # Add the user feedback feature to the page.
      loadFeedback(@config.options.userVoice)

      # Begin initialization.
      i18n.traverse()

      # Retrieve all singleton instances as well as the collection for user-created snippets.
      models.fetch (result) =>
        {settings, editorSettings, snippets} = result

        # Create views for the important models and collections.
        @editor   = new EditorView({ settings: editorSettings })
        @settings = new SettingsView({ model: settings })
        @snippets = new SnippetsView({ collection: snippets })

        # Render these new views.
        @editor.render()
        @settings.render()
        @snippets.render()

        # Ensure that views are updated accordingly when snippets are selected/deselected.
        snippets.on 'selected deselected', (snippet) =>
          if snippet.get('selected') then @update(snippet) else @update()

        selectedSnippet = snippets.findWhere({ selected: yes })
        @update(selectedSnippet) if selectedSnippet

        # Ensure the current year is displayed throughout, where appropriate.
        $('.js-insert-year').html("#{new Date().getFullYear()}")

        # Bind tab selection event to all tabs.
        initialSnippetDisplay = initialTabChange = yes

        $('a[data-tabify]').on 'click', ->
          target  = $(@).data('tabify')
          $nav    = $("header.navbar .nav a[data-tabify='#{target}']")
          $parent = $nav.parent('li')

          unless $parent.hasClass('active')
            $parent.addClass('active').siblings().removeClass('active')
            $(target).removeClass('hide').siblings('.tab').addClass('hide')

            id = $nav.attr('id')

            settings.save({ tab: id })
            .then ->
              unless initialTabChange
                analytics.track('Tabs', 'Changed', _.capitalize(id.match(/(\S*)_nav$/)[1]))

              if id is 'snippets' and initialSnippetDisplay
                initialSnippetDisplay = no
                page.snippets.list.showSelected()

              initialTabChange = no

              $(document.body).scrollTop(0)

        # Reflect the previously persisted tab initially.
        $("##{settings.get 'tab'}").trigger('click')

        # Ensure that form submissions don't reload the page.
        $('form.js-no-submit').on 'submit', -> false

        # Support *goto* navigation elements that change the current scroll position when clicked.
        $('[data-goto]').on 'click', ->
          switch $(@).data('goto')
            when 'top' then $(document.body).scrollTop(0)

        # Bind analytical tracking events to key footer buttons and links.
        $('footer a[href*="neocotic.com"]').on 'click', ->
          analytics.track('Footer', 'Clicked', 'Homepage')

        # Setup and configure donation buttons.
        $('#donation input[name="hosted_button_id"]').val(@config.options.payPal)
        $('.js-donate').on 'click', ->
          $(@).tooltip('hide')

          $('#donation').submit()

          analytics.track('Donate', 'Clicked')

        activateTooltips()

  # Update the primary views with the selected `snippet` provided.
  update: (snippet) ->
    @editor.update(snippet)
    @snippets.update(snippet)

# Create an global instance of `OptionsPage` and initialize it once the DOM is ready.
page = window.page = new OptionsPage()

$ -> page.init()
