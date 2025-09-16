def require_directory(dir)
  Dir[File.join(dir, '*.rb')]&.sort&.each do |file|
    require file unless file == __FILE__
  end
end

require_directory __dir__
