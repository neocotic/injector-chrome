# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Injector
# --------

# Primary global namespace.
Injector = window.Injector = {}

# Retrieve the value of the given `property` from the "parent" of the context class.
#
# If that value is a function, then invoke it with the additional `args` and retrieve the return
# value of that call instead.
getSuper = (property, args...) ->
  result = @constructor.__super__[property]

  if _.isFunction result then result.apply @, args else result

# Setup the Chrome storage for the specified `model` (may also be a collection) based on the
# `storage` property, if it exists.
setupStorage = (model) ->
  {name, type} = model.storage ? {}

  if name and type
    model.chromeStorage = new Backbone.ChromeStorage name, type

# Model
# -----

# Base model to be used within our application.
Model = Injector.Model = Backbone.Model.extend {

  # Called internally by `initialize`. This should be overridden for custom initialization logic.
  init: ->

  # Override `initialize` to hook in our own custom model initialization.
  initialize: ->
    setupStorage @

    @init arguments...

  # Allow models to access "parent" properties easily.
  super: getSuper

}

# The identifier used by single models.
singletonId = 'singleton'

# A singleton model where implementations should only have one persisted instance.
SingletonModel = Injector.SingletonModel = Injector.Model.extend {

  # Override `initialize` to set the singleton identifier.
  initialize: (attributes, options) ->
    @set @idAttribute, singletonId, options

    Injector.Model::initialize.apply @, arguments

}, {

  # Retrieve a singleton instance of the model.
  fetch: (callback) ->
    model = new @
    model.fetch().then ->
      callback model

}

# Collection
# ----------

# Base collection to be used within our application.
Collection = Injector.Collection = Backbone.Collection.extend {

  # The default model for a collection. This should be overridden in most cases.
  model: Model

  # Called internally by `initialize`. This should be overridden for custom initialization logic.
  init: ->

  # Override `initialize` to hook in our own custom collection initialization.
  initialize: ->
    setupStorage @

    @init arguments...

  # Allow collections to access "parent" properties easily.
  super: getSuper

}

# View
# ----

# Base view to be used within our application.
View = Injector.View = Backbone.View.extend {

  # Called internally by `initialize`. This should be overridden for custom initialization logic.
  init: ->

  # Override `initialize` to hook in our own custom view initialization.
  initialize: (@options) ->
    @init arguments...

  # Indicate whether or not this view has an underlying collection associated with it.
  hasCollection: ->
    @collection?

  # Indicate whether or not this view has an underlying model associated with it.
  hasModel: ->
    @model?

  # Allow views to access "parent" properties easily.
  super: getSuper

}

# Router
# ------

# Base router to be used within our application.
Router = Injector.Router = Backbone.Router.extend {

  # Called internally by `initialize`. This should be overridden for custom initialization logic.
  init: ->

  # Override `initialize` to hook in our own custom model initialization.
  initialize: ->
    @init arguments...

  # Allow routers to access "parent" properties easily.
  super: getSuper

}

# History
# -------

# Base history implementation to be used within our application.
History = Injector.History = Backbone.History.extend

  # Allow history implementations to access "parent" properties easily.
  super: getSuper
