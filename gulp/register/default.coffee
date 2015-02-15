runSequence = require 'run-sequence'

module.exports = ->

  runSequence 'clean'
  , 'build'
  , 'watch', 'browsersync'