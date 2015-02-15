echo = console.log
browserSync = require 'browser-sync'

module.exports = ->

  browserSync
    server:
      baseDir: './build'
      index: 'index.html'
    port: 9000
    startPath: '/'
    watchTask: true
