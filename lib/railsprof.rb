require 'railsprof/version'
require 'railsprof/logger'
require 'railsprof/profiler'

module Railsprof
  DEFAULT_OPTIONS = {
    session: {},
    cookies: {},
    params: {},
    warmups: 1,
    runs: 1,
    log_level: Logger::INFO,
    threshold: 0.5,
    app_paths: %w(app lib config),
    gems: []
  }
end
