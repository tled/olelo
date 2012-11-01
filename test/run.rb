begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError
  puts 'simplecov not found - no coverage generated'
end

Dir.glob('test/*.rb').each do |file|
  if file != __FILE__
    require File.expand_path(file)
  end
end
