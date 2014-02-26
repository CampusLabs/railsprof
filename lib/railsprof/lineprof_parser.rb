require 'erb'

class Railsprof::LineprofParser
  # rblineprof formatting
  # {
  #   "/path/to/file" => [
  #     # File stats (Line 0)
  #     [total_time, child_time, excl_time, total_cpu, child_cpu, excl_cpu],
  #     # Line 1 stats
  #     [wall, cpu, calls, allocations]
  #     # Line 2 stats
  #     [wall, cpu, calls, allocations]
  #     ...
  #   ]
  # }
  attr_reader :logger, :options

  def initialize(profile, paths, threshold_ms: 0.5, **options)
    @threshold = threshold_ms * 1000
    @paths = paths
    @profile = profile
    @friendly_paths = {}
    @profiled_source = {}
    @logger = options[:logger]
    @total_ms = options[:total_ms]
    @options = options

    @profiled_files = profile
      .reduce([]) do |files, (file, lines)|
        total = lines[0][0]
        if total > @threshold # && !file[/benchmark|\.rake$/] # time in micros
          @friendly_paths[file] = @paths.relative_path_for(file)
          #     [total_time, child_time, excl_time, total_cpu, child_cpu, excl_cpu],
          tt, _ct, _et, tc, _cc, _ec = lines[0]
          # total, cpu, idle, exclusive %
          file_timings = [tt, tc, tt - tc].map { |n| n / 1000.0 }
          files << [file, *file_timings]
        end
        files
      end
      .sort_by { |f| -f[1] }
  end

  def cli_report
    logger.info "\n-- total - cpu - idle - filename --\n"

    @profiled_files.each do |file, *timings|
      str = (['%8.1fms'] * 3).join(' - ')
      logger.info "#{str}  %s\n" % (timings + [@friendly_paths[file]])
    end
  end

  def html_report
    filename = [
      '/tmp/railsprof',
      File.basename(Dir.pwd),
      Time.now.to_s(:number),
    ].join('-') + '.html'

    @profiled_files.each { |f, _| file_output(f) }

    b = binding
    template = File.read(File.dirname(__FILE__) +
                         '/views/railsprof-tmpl.html.erb')
    ERB.new(template, 0, "", "@html_output").result(b)
    File.open(filename, 'w') { |f| f.write(@html_output) }

    logger.info "Results in '#{filename}'"
    `open #{filename}`
  end

  private

  def file_output(file)
    @profiled_source[file] = "\n % 8s   + % 8s   (called)\n" % %w(cpu idle)
    File.readlines(file).each_with_index do |line, num|
      wall, cpu, calls, _allocations = @profile[file][num + 1]
      # excl cpu, excl idle, total cpu, total idle
      @profiled_source[file] <<
        if calls && calls > 0
          '% 8.1fms + % 8.1fms  % 8s | %s' %
            [cpu / 1000.0, (wall - cpu) / 1000.0, "(#{calls})", line]
        else
          '                                  | %s' % line
        end
    end
  end
end
