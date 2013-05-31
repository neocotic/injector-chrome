# [Script Runner](http://neocotic.com/script-runner)  
# (c) 2013 Alasdair Mercer  
# Freely distributable under the MIT license

# Script Runner
# -------------

# TODO: Document
models.fetch (result) ->
  host   = location.host.replace /^www\./, ''
  script = result.scripts.findWhere { host }

  # TODO: Execute `script.code` in sandbox
  eval script.get 'code' if script
