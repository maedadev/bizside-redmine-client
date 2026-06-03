$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "logger"
require "bizside/redmine/client"

require "minitest/autorun"
require 'webmock/minitest'
