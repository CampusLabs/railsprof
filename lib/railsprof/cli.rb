require 'optparse'

class Railsprof::CLI
  def self.start
    logger = Railsprof::Logger.new(STDOUT)
    logger.level = Logger::INFO
    options = {}

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: railsprof [options] /path'

      opts.on('-h', '--help', 'Show this message') do
        puts opts.help
        exit
      end

      opts.on('--version', 'Show version') do
        puts "Version #{Railsprof::VERSION}"
        exit
      end

      opts.on('-v', '--verbose',
              'Run verbosely') do
        logger.level = options[:log_level] = Logger::DEBUG
      end

      opts.on('-e', '--environment ENV',
              'Environment (defaults to RAILS_ENV)') do |env|
        ENV['RAILS_ENV'] = env
      end

      opts.on('-q', '--query-param KEY=VAL',
              'Add query paramter (-q key=val {key: "val"}') do |q|
        options[:params] ||= {}
        key, val = q.split('=', 2)
        options[:params][key] = val
      end

      # TODO add session support
      # opts.on('-s', '--session KEY=VAL',
      #         'Session info (-s user=3 --> {user: 3})') do |s|
      #   options[:session] ||= {}
      #   key, val = s.split('=', 2)

      #   # parse session value in ruby if possible
      #   options[:session][key.to_sym] =
      #     begin
      #       eval val
      #     rescue NameError
      #       val
      #     end

      #   logger.debug "Added to session: {#{key.to_sym.inspect} => #{val.inspect}}"
      # end

      # TODO add cookie support
      # opts.on('-c', '--cookie KEY=VAL',
      #         'Add cookie (-c remember=all --> {:remember => "all"})') do |s|
      #   options[:cookies] ||= {}
      #   key, val = s.split('=', 2)

      #   options[:cookies][key.to_sym] = val

      #   logger.debug "Added to cookiejar: {#{key.to_sym.inspect} => #{val.inspect}}"
      # end

      # TODO add host support
      # opts.on('--host HOST',
      #         'Host for request (--host www.blah.com)') do |h|
      #   options[:host] = h
      # end

      # TODO add port support
      # opts.on('--port PORT',
      #         Integer,
      #         'Port for request (--port 3000)') do |p|
      #   options[:port] = p
      # end

      opts.on('-w', '--warmups N', Integer,
              'Number of warmup runs on stack, default ' +
              Railsprof::DEFAULT_OPTIONS[:warmups].to_s) do |w|
        options[:warmups] = w
      end

      opts.on('-n', '--num-runs N', Integer,
              'Number of runs in profiling mode, default ' +
              Railsprof::DEFAULT_OPTIONS[:runs].to_s) do |r|
        options[:runs] = r
      end

      opts.on('-t', '--threshold N', Float,
              'Threshold for file output in millis, default: ' +
              Railsprof::DEFAULT_OPTIONS[:threshold].to_s) do |t|
        options[:threshold] = t
      end

      opts.on('-d', '--directory DIR',
              'Local paths to profile, default: ' +
              Railsprof::DEFAULT_OPTIONS[:app_paths].join(', ')) do |d|
        options[:app_dirs] ||= []
        options[:app_dirs] << d
      end

      opts.on('-g', '--gem GEM',
              'Gems to profile, default: ' +
              Railsprof::DEFAULT_OPTIONS[:gems].join(', ')) do |d|
        options[:gems] ||= []
        options[:gems] << d
      end

      # for capturing args before '--'
      # opts.on do |h|
      #   puts "head: #{h.inspect}"
      # end

      # # for capturing args after '--'
      # opts.on_tail do |t|
      #   puts "tail: #{t.inspect}"
      # end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    args = opt_parser.parse!

    if args.empty?
      puts opt_parser.help
      exit
    end

    Railsprof::Profiler.new(args, options).profile!
  end
end
