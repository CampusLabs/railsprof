require 'active_support'
require 'active_support/benchmarkable'
require 'active_support/core_ext/hash'
require 'benchmark'
require 'rblineprof'
require 'railsprof/paths'
require 'railsprof/lineprof_parser'

class Railsprof::Profiler
  attr_reader :logger, :options
  attr_accessor :gem_roots

  def initialize(args, opts = {})
    @options = Railsprof::DEFAULT_OPTIONS.merge(opts)

    @logger = options[:logger] || Railsprof::Logger.new(STDOUT)
    @logger.level = options[:log_level] || Logger::INFO

    @paths = Railsprof::Paths.new(options.slice(:gems, :app_paths))

    args.unshift('GET') if args.size == 1

    if args.size == 2
      args.first.upcase!
      @method, @path = args
    else
      fail ArgumentError, "excepted METHOD PATH, received: #{args.join(' ')}"
    end

    logger.debug "Request: #@method #@path"
    logger.debug "Options: #{options.inspect}"
  end

  def profile!
    load_app!
    options[:warmups].times do |i|
      say_with_time("Warmup ##{i + 1}") { run }
    end
    if options[:runs] > 0
      logger.info 'Profiling....'
      
      total = say_with_time('All profiles') do
        @profile = lineprof(@paths.regexp) do
          options[:runs].times do |i|
            say_with_time("Profile ##{i + 1}") { run }
          end
        end
      end
    end

    parser = Railsprof::LineprofParser.new(
      @profile, @paths,
      threshold_ms: options[:threshold],
      logger: logger,
      profiler_options: @options,
      total_ms: total
    )

    parser.cli_report
    parser.html_report
  end

  def run
    load_app!

    begin
      ret = Rails.application.routes.call(mock_request)
    rescue Exception => e
      if logger.level == Logger::DEBUG
        raise e
      else
        logger.info "#{e.class.name} raised: #{e.message}"
        logger.info "run railsprof with -v to see stacktrace"
        exit 1
      end
    end

    status, _ = ret
    logger.warn "Status code #{status} received" if status != 200

    ret
  end

  private

  def mock_request
    Rack::MockRequest.env_for(
      @path,
      method: @method,
      params: options[:params]
      # input: form body data
    )
    .merge({
      # 'rack.session' => options[:session]
    })
  end

  def load_app!
    return if defined? @loaded

    logger.info 'App loading...'
    env_file = Dir.pwd + '/config/environment.rb'
    if File.exists?(env_file)
      ms = Benchmark.ms { load env_file }
      logger.info 'Loaded in %.2f secs (%s mode)' % [ms / 1000.0, Rails.env]
    else
      logger.error 'Exiting... an application with config/environment.rb was expected'
      exit 1
    end
    @loaded = true
  end

  def say_with_time(msg, level: 'info', &block)
    ret = nil
    ms = Benchmark.ms { ret = block.call }
    logger.send(level, '%s completed in %.2fms' % [msg, ms])
    ms
  end
end

=begin
namespace :api do
  GEMS = %w[hasherdashery active_interaction]
  APP_DIRS = %w[lib app config gems]

  desc 'profile an API endpoint, return rblineprof data'

  task :profile, [:route] => :environment do |t, args|
    route = args[:route]
    status, headers, body = nil
    gem_roots = Set.new

    paths =
      APP_DIRS.map { |d| Rails.root.join(d).to_s } +
      GEMS.map { |g|
        gem_dir = Gem::Specification.find_by_name(g).gem_dir
        gem_roots << Pathname.new(gem_dir).parent
        gem_dir
      }

    path_pattern = Regexp.new paths.map { |p| Regexp.escape(p) }.join('|')

    print "Warming up request... "
    warmup_ms = Benchmark.ms { status, headers, body = internal_request(route) }
    printf "finished in %dms with status %s\n" % [warmup_ms, status]


    profile = lineprof(path_pattern) do
      status, headers, body = nil
      print "Profiling request... "
      profiled_ms = Benchmark.ms { status, headers, body = internal_request(route) }
      printf "finished in %dms with status %s\n" % [profiled_ms, status]
    end

    # rblineprof formatting
    # {
    #   "/path/to/file" => [
    #     # File stats
    #     [total_time, child_time, exclusive_time, allocations],
    #     # Line 1 stats
    #     [wall, cpu, calls, allocations]
    #     # Line 2 stats
    #     [wall, cpu, calls, allocations]
    #     ...
    #   ]
    # }

    friendly_paths = {}
    profiled_source = {}

    profiled_files = profile
      .inject([]) do |files, (file, ((total, _, exclusive, allocs), _))|
        if total > 500 && !file[/benchmark|\.rake$/] # time in micros
          files << [file, total, exclusive, allocs]

          path = Pathname.new(file)
          friendly_paths[file] =
            if file[Rails.root.to_s]
              path.relative_path_from(Rails.root)
            elsif gem_root = gem_roots.detect { |r| file[r.to_s] }
              path.relative_path_from(gem_root)
            else
              file
            end

          profiled_source[file] = "\n"
          File.readlines(file).each_with_index do |line, num|
            wall, cpu, calls, allocations = profile[file][num + 1]
            profiled_source[file] <<
              if calls && calls > 0
                '% 8.1fms + % 8.1fms (% 5d) | %s' %
                  [cpu / 1000.0, (wall - cpu) / 1000.0, calls, line]
              else
                '                                | %s' % line
              end
          end
        end
        files
      end
      .sort_by { |f| -f[1] }

    puts "\n-- Top files by execution time (ms / filename) --\n"

    profiled_files.each do |file, total, exclusive, allocs|
      printf "%8.3fms total %8.3fms excl %9d allocs %s \n" %
        [total / 1000.0, exclusive / 1000.0, allocs, friendly_paths[file]]
    end

    filename = [
      '/tmp/railsprof',
      Rails.root.basename,
      Time.now.to_s(:number),
    ].join('-') + '.html'

    b = binding
    template = File.read('railsprof-tmpl.html.erb')
    ERB.new(template, 0, "", "@html_output").result(b)

    File.open(filename, 'w') { |f| f.write(@html_output) }

    `open #{filename}`
  end

  def internal_request(path, params={})
    request_env = Rack::MockRequest.env_for(path, params: params.to_query).merge({
      # 'rack.session' => session
    })

    Rails.application.routes.call(request_env)
  end
end
=end

