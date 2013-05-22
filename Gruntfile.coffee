module.exports = (grunt) ->

  # Configuration
  # -------------

  pkg = grunt.file.readJSON 'package.json'

  grunt.initConfig {

    pkg

    clean:
      build: 'bin/*'

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
        src:    ['**', '!less/', '!lib/*.coffee']
        dest:   'bin/'

      dist:
        expand: yes
        cwd:    'bin/'
        src:    ['**', '!lib/*.js']
        dest:   'dist/temp/'

    coffee:
      build:
        expand: yes
        cwd:    'src/lib/'
        src:    '*.coffee'
        dest:   'bin/lib/'
        ext:    '.js'

    docco:
      dist:
        src: 'src/lib/*.coffee'
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
          cwd:    'bin/lib/'
          src:    '*.js'
          dest:   'dist/temp/lib/'
        ]
        options:
          banner: """
            /*! Script Runner v<%= pkg.version %> | (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %> | <%= pkg.licenses[0].type %> License */

          """

  }

  # Tasks
  # -----

  for dependency of pkg.devDependencies when ~dependency.indexOf 'grunt-'
    grunt.loadNpmTasks dependency

  grunt.registerTask 'build', [
    'clean:build'
    'copy:build'
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

  grunt.registerTask 'default', ['build']

  # Remove all of the long message descriptions and placeholder examples as they're not required by
  # users and Chrome Web Store has a size limit for locale files.
  grunt.registerMultiTask 'locale-prepare', 'Locale JSON preparation task', ->
    files = grunt.file.expand @data.files

    files.forEach (file) ->
      grunt.log.write "Preparing \"#{file}\"..."

      messages = grunt.file.readJSON file

      for name, message of messages
        delete message.description

        if message.placeholders
          delete placeholder.example for key, placeholder of message.placeholders

      grunt.file.write file, JSON.stringify messages

      grunt.log.ok()
