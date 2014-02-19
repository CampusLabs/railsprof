require 'logger'

class Railsprof::Logger < ::Logger
  SEVERITY_TO_COLOR_MAP = Hash[*%w(
    DEBUG  0;37
    INFO   32
    WARN   33
    FATAL  31
    UKNOWN 37
  )]

  def initialize(*_)
    super
    self.formatter = ->(severity, datetime, progname, msg) {
      [
        "\033[#{SEVERITY_TO_COLOR_MAP[severity]}m",
        '%-6s' % "#{severity.downcase}",
        "\033[0m #{msg.strip}\n"
      ].join
    }
  end
end
