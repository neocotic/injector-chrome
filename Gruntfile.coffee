module.exports = (grunt) ->

  # Configuration
  # -------------

  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json')

    clean: {
      build:        [ 'bin/img/**', 'bin/vendor/**', 'bin/*.html' ]
      buildAll:     'bin/*'
      buildJSON:    [ 'bin/_locales/**', 'bin/*.json' ]
      buildStyles:  'bin/less/*'
      buildScripts: 'bin/coffee/*'

      dist:      'dist/*'
      distAfter: 'dist/temp/'

      docs: 'docs/*'
    }

    compress: {
      dist: {
        files: [
          {
            expand: true
            cwd:    'dist/temp/'
            src:    '**/*'
          }
        ]
        options: {
          archive: 'dist/Injector.zip'
          level:   9
          pretty:  yes
        }
      }
    }

    copy: {
      build: {
        expand: yes
        cwd:    'src/'
        src:    [ 'img/**', 'vendor/**', '*.html' ]
        dest:   'bin/'
      }

      buildStyles: {
        expand: yes
        cwd:    'src/'
        src:    [ 'css/**' ]
        dest:   'bin/'
      }

      buildScripts: {
        expand: yes
        cwd:    'src/'
        src:    [ 'js/**' ]
        dest:   'bin/'
      }

      dist: {
        expand: yes
        cwd:    'bin/'
        src:    [ '**', '!js/*' ]
        dest:   'dist/temp/'
      }
    }

    coffee: {
      build: {
        expand: yes
        cwd:    'src/coffee/'
        src:    '*.coffee'
        dest:   'bin/js/'
        ext:    '.js'
      }
    }

    cson: {
      buildJSON: {
        expand: yes
        cwd:    'src/'
        src:    '**/*.cson'
        dest:   'bin/'
        ext:    '.json'
      }
    }

    docco: {
      dist: {
        src: 'src/coffee/*'
        options: {
          output: 'docs/'
        }
      }
    }

    'json-minify': {
      dist: {
        files: 'dist/temp/**/*.json'
      }
    }

    less: {
      build: {
        files: [
          {
            expand: yes
            cwd:    'src/less/'
            src:    '*.less'
            dest:   'bin/css/'
            ext:    '.css'
          }
        ]
        options: {
          compress: yes
        }
      }
    }

    'locale-prepare': {
      dist: {
        files: 'dist/temp/_locales/**/*.json'
      }
    }

    uglify: {
      dist: {
        files: [
          {
            expand: yes
            cwd:    'bin/js/'
            src:    '*.js'
            dest:   'dist/temp/js/'
          }
        ]
        options: {
          banner: """
            /*! Injector v<%= pkg.version %> | (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %> | <%= pkg.licenses[0].type %> License */

          """
        }
      }
    }

    watch: {
      build: {
        files: [ 'src/img/**', 'src/vendor/**', 'src/*.html' ]
        tasks: [ 'clean:build', 'copy:build' ]
      }

      buildJSON: {
        files: [ 'src/_locales/**', 'src/*.cson' ]
        tasks: [ 'clean:buildJSON', 'cson' ]
      }

      buildStyles: {
        files: [ 'src/css/**', 'src/less/**' ]
        tasks: [ 'clean:buildStyles', 'copy:buildStyles', 'less' ]
      }

      buildScripts: {
        files: [ 'src/js/**', 'src/coffee/**' ]
        tasks: [ 'clean:buildScripts', 'copy:buildScripts', 'coffee' ]
      }
    }

  })

  # Tasks
  # -----

  require('load-grunt-tasks')(grunt)

  grunt.loadTasks('tasks')

  grunt.registerTask('build', [
    'clean:buildAll'
    'copy:build'
    'copy:buildScripts'
    'copy:buildStyles'
    'coffee'
    'cson'
    'less'
  ])

  grunt.registerTask('dist', [
    'clean:dist'
    'copy:dist'
    'locale-prepare'
    'json-minify'
    'uglify'
    'compress'
    'clean:distAfter'
  ])

  grunt.registerTask('docs', [
    'clean:docs'
    'docco'
  ])

  grunt.registerTask('default', [ 'build' ])
