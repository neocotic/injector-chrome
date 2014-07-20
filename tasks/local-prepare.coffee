# Grunt task that removes all of the long message descriptions and placeholder examples as they're not required by
# users and Chrome Web Store has a size limit for locale files.

module.exports = (grunt) ->

  int17 = require('int17')

  prepareFile = (file) ->
    grunt.log.write("Preparing '#{file}'...")

    grunt.file.write(file, JSON.stringify(int17.optimize(grunt.file.readJSON(file))))

    grunt.log.ok()

  grunt.registerMultiTask 'locale-prepare', 'Locale JSON preparation task', ->
    grunt.file.expand(@data.files).forEach(prepareFile)
