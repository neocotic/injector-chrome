# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Editor
# ------

# TODO: Document
editor = ace.edit 'editor'

# TODO: Document
updateEditor = (options) ->
  editor.setTheme "ace/theme/#{options.theme}"
  editor.getSession().setMode "ace/mode/#{options.mode}"

# Feedback
# --------

# Indicate whether or not the user feedback feature has been added to the page.
feedbackAdded = no

# Add the user feedback feature to the page.
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
      tab_label:     i18n.get 'opt_feedback_button'
      tab_color:     '#333'
      tab_position:  'middle-left'
      tab_inverted:  yes
    }
  ]

  # Ensure that the widget isn't loaded again.
  feedbackAdded = yes

# User interface
# --------------

# Activate tooltip effects, optionally only within a specific context.
activateTooltips = (selector) ->
  log.trace()

  base = $ selector or document

  # Reset all previously treated tooltips.
  base.find('[data-original-title]').each ->
    $this = $ this

    $this.tooltip 'destroy'
    $this.attr 'title', $this.attr 'data-original-title'
    $this.removeAttr 'data-original-title'

  # Apply tooltips to all relevant elements.
  base.find('[title]').each ->
    $this     = $ this
    placement = $this.attr 'data-placement'
    placement = if placement? then utils.trimToLower placement else 'top'

    $this.tooltip {container: $this.attr('data-container') ? 'body', placement}

# Options page setup
# ------------------

options = window.options = new class Options extends utils.Class

  # Public variables
  # ----------------

  # Configuration data that is to be loaded at runtime.
  config: {}

  # Current version of Script Runner.
  version: ''

  # Public functions
  # ----------------

  # Initialize the options page.  
  # This will involve inserting and configuring the UI elements as well as loading the current
  # settings.
  init: ->
    # Add support for analytics if the user hasn't opted out.
    analytics.init()

    # It's nice knowing what version is running.
    {@version} = chrome.runtime.getManifest()

    # Load the configuration data from the file before storing it locally.
    $.getJSON utils.url('configuration.json'), (@config) =>
      # Add the user feedback feature to the page.
      loadFeedback @config.options.userVoice

      # Begin initialization.
      i18n.traverse()

      # Ensure the current year is displayed throughout, where appropriate.
      $('.year-repl').html "#{new Date().getFullYear()}"

      # Bind tab selection event to all tabs.
      initialTabChange = yes
      $('a[tabify]').on 'click', ->
        target = $(this).attr 'tabify'
        nav    = $ "#navigation a[tabify='#{target}']"
        parent = nav.parent 'li'

        unless parent.hasClass 'active'
          parent.addClass('active').siblings().removeClass 'active'
          $(target).show().siblings('.tab').hide()

          id = nav.attr 'id'
          chrome.storage.sync.set activeTab: id, ->
            unless initialTabChange
              id = utils.capitalize id.match(/(\S*)_nav$/)[1]
              analytics.track 'Tabs', 'Changed', id

            initialTabChange = no
            $(document.body).scrollTop 0

      # Reflect the previously persisted tab initially.
      chrome.storage.sync.get activeTab: 'general_nav', (settings) ->
        $("##{settings.activeTab}").trigger 'click'

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

      # TODO: Comment
      updateEditor mode: 'javascript', theme: 'github'

# Initialize `options` when the DOM is ready.
$ -> options.init()
