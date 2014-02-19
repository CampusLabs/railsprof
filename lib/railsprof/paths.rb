class Railsprof::Paths
  def initialize(gems: [], app_paths: [])
    @pwd = Pathname.new(Dir.pwd)
    @gem_roots = Set.new
    @paths =
      app_paths.map { |d| [Dir.pwd, d].join('/') } +
      gems.map { |g|
        gem_dir = Gem::Specification.find_by_name(g).gem_dir
        @gem_roots << Pathname.new(gem_dir).parent
        gem_dir
      }
  end

  def regexp
    Regexp.new(
      @paths.map { |p| Regexp.escape(p) }.join('|')
    )
  end

  def relative_path_for(file)
    path = Pathname.new(file)
    if file[@pwd.to_s]
      path.relative_path_from(@pwd)
    elsif gem_root = @gem_roots.detect { |r| file[r.to_s] }
      path.relative_path_from(gem_root)
    else
      file
    end
  end
end
