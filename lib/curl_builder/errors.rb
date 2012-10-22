module CurlBuilder
  module Errors
    Error     = Class.new(StandardError)
    TaskError = Class.new(Error)
  end
end