# Module dependencies
# -------------------

int17 = require 'int17'

module.exports = (grunt) ->

  # Configuration
  # -------------

  pkg = grunt.file.readJSON 'package.json'

  grunt.initConfig {

    pkg

    clean:
      build:        [ 'bin/_locales/**', 'bin/fonts/**', 'bin/*.json', 'bin/*.html' ]
      buildStyles:  'bin/css/*'
      buildScripts: 'bin/js/*'

      dist:      'dist/*'
      distAfter: 'dist/temp/'

      docs: 'docs/*'

    compress:
      dist:
        files: [
          expand: true
          cwd:    'dist/temp/'
          src:    '**/*'
        ]
        options:
          archive: 'dist/ScriptRunner.zip'
          level:   9
          pretty:  yes

    copy:
      build:
        expand: yes
        cwd:    'src/'
        src:    [ '_locales/**', 'fonts/**', '*.json', '*.html' ]
        dest:   'bin/'

      buildStyles:
        expand: yes
        cwd:    'src/'
        src:    [ 'css/**' ]
        dest:   'bin/'

      buildScripts:
        expand: yes
        cwd:    'src/'
        src:    [ 'js/**' ]
        dest:   'bin/'

      dist:
        expand: yes
        cwd:    'bin/'
        src:    [ '**', '!js/*' ]
        dest:   'dist/temp/'

    coffee:
      build:
        expand: yes
        cwd:    'src/coffee/'
        src:    '*.coffee'
        dest:   'bin/js/'
        ext:    '.js'

    docco:
      dist:
        src: 'src/coffee/*'
        options:
          output: 'docs/'

    'json-minify':
      dist:
        files: 'dist/temp/**/*.json'

    less:
      build:
        files: [
          expand: yes
          cwd:    'src/less/'
          src:    '*.less'
          dest:   'bin/css/'
          ext:    '.css'
        ]
        options:
          compress: yes

    'locale-prepare':
      dist:
        files: 'dist/temp/_locales/**/*.json'

    uglify:
      dist:
        files: [
          expand: yes
          cwd:    'bin/js/'
          src:    '*.js'
          dest:   'dist/temp/js/'
        ]
        options:
          banner: """
            /*! Script Runner v<%= pkg.version %> | (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %> | <%= pkg.licenses[0].type %> License */

          """

    watch:
      build:
        files: [ 'src/_locales/**', 'src/fonts/**', 'src/*.json', 'src/*.html' ]
        tasks: [ 'clean:build', 'copy:build' ]

      buildStyles:
        files: [ 'src/css/**', 'src/less**' ]
        tasks: [ 'clean:buildStyles', 'copy:buildStyles', 'less' ]

      buildScripts:
        files: [ 'src/js/**', 'src/coffee/**' ]
        tasks: [ 'clean:buildScripts', 'copy:buildScripts', 'coffee' ]

  }

  # Tasks
  # -----

  for dependency of pkg.devDependencies when ~dependency.indexOf 'grunt-'
    grunt.loadNpmTasks dependency

  grunt.registerTask 'build', [
    'clean:build'
    'clean:buildScripts'
    'clean:buildStyles'
    'copy:build'
    'copy:buildScripts'
    'copy:buildStyles'
    'coffee'
    'less'
  ]

  grunt.registerTask 'dist', [
    'clean:dist'
    'copy:dist'
    'locale-prepare'
    'json-minify'
    'uglify'
    'compress'
    'clean:distAfter'
  ]

  grunt.registerTask 'docs', [
    'clean:docs'
    'docco'
  ]

  grunt.registerTask 'default', [ 'build' ]

  # Remove all of the long message descriptions and placeholder examples as they're not required by
  # users and Chrome Web Store has a size limit for locale files.
  grunt.registerMultiTask 'locale-prepare', 'Locale JSON preparation task', ->
    files = grunt.file.expand @data.files

    files.forEach (file) ->
      grunt.log.write "Preparing \"#{file}\"..."

      grunt.file.write file, JSON.stringify int17.optimize grunt.file.readJSON file

      grunt.log.ok()
