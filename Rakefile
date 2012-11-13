task default: :test

def shrink_js(t)
  #sh "cat #{t.prerequisites.sort.join(' ')} > #{t.name}"
  sh 'java -jar tools/google-compiler*.jar --dev_mode EVERY_PASS --compilation_level SIMPLE_OPTIMIZATIONS ' +
     t.prerequisites.sort.map {|x| "--js #{x}" }.join(' ')  + " > #{t.name}"
end

def sass(file)
  `sass -C -I #{File.dirname(file)} -I static/themes -t compressed #{file}`
end

def spew(file, content)
  File.open(file, 'w') {|f| f.write(content) }
end

file 'plugins/utils/pygments.scss' do
  sh "pygmentize -S default -f html -a .highlight > plugins/utils/pygments.scss"
end

file('static/themes/atlantis/style.css' => Dir.glob('static/themes/atlantis/*.scss') + Dir.glob('static/themes/lib/*.scss')) do |t|
  puts "Creating #{t.name}..."
  content = "@media screen{#{sass(t.name.gsub('style.css', 'screen.scss'))}}@media print{#{sass(t.name.gsub('style.css', 'print.scss'))}}"
  spew(t.name, content)
end

rule '.css' => ['.scss'] do |t|
  puts "Creating #{t.name}..."
  spew(t.name, sass(t.source))
end

file('static/script.js' => Dir.glob('static/script/*.js')) { |t| shrink_js(t) }
file('plugins/treeview/script.js' => Dir.glob('plugins/treeview/script/*.js')) {|t| shrink_js(t) }
file('plugins/misc/fancybox/script.js' => Dir.glob('plugins/misc/fancybox/script/*.js')) {|t| shrink_js(t) }
file('plugins/editor/markup/script.js' => Dir.glob('plugins/editor/markup/script/*.js')) {|t| shrink_js(t) }
file('plugins/history/script.js' => Dir.glob('plugins/history/script/*.js')) {|t| shrink_js(t) }

namespace :gen do
  desc('Shrink JS files')
  task js: %w(static/script.js plugins/treeview/script.js plugins/misc/fancybox/script.js plugins/editor/markup/script.js plugins/history/script.js)

  desc('Compile CSS files')
  task css: %w(static/themes/atlantis/style.css
                  plugins/treeview/treeview.css
                  plugins/utils/pygments.css
                  plugins/aspects/gallery/gallery.css
                  plugins/misc/fancybox/jquery.fancybox.css
                  plugins/blog/blog.css)
end

desc 'Run tests with bacon'
task test: FileList['test/*_test.rb'] do |t|
  sh "bacon -q -Ilib:test test/run.rb"
end

desc 'Cleanup'
task :clean do |t|
  FileUtils.rm_rf 'doc/api'
  FileUtils.rm_rf 'coverage'
  FileUtils.rm_rf '.wiki/cache'
  FileUtils.rm_rf '.wiki/log'
end

namespace :doc do
  desc 'Generate documentation'
  task :gen    do; sh "yard doc -o doc/api 'lib/**/*.rb' 'plugins/**/*.rb'"; end

  desc 'Start YARD documentation server'
  task :server do; sh 'yard server --reload'; end

  desc 'Check YARD documentation'
  task :check  do; sh "yardcheck 'lib/**/*.rb' 'plugins/**/*.rb'"; end
end

namespace :locale do
  desc 'Sort locale yaml files'
  task :sort do
    require File.join(File.dirname(__FILE__), 'lib/olelo/virtualfs')
    require 'i18n_yaml_sorter'

    Dir['**/*.rb'].each do |file|
      begin
        locale = Olelo::VirtualFS::Embedded.new(file).read('locale.yml')
      rescue
        next
      end
      puts "Sorting #{file}"
      result = I18nYamlSorter::Sorter.new(StringIO.new(locale)).sort
      if result != locale
        puts "Sorted #{file}:\n#{result}\n"
      end
    end

    Dir['**/locale.yml'].each do |file|
      puts "Sorting #{file}"
      system("sort_yaml < #{file} > #{file}.sorted && mv #{file}.sorted #{file}")
    end
  end

  desc 'Check locales for missing keys'
  task :check do
    require File.join(File.dirname(__FILE__), 'lib/olelo/virtualfs')
    require 'yaml'
    files = {}
    Dir['**/*.rb'].each do |file|
      begin
        files[file] = Olelo::VirtualFS::Embedded.new(file).read('locale.yml')
      rescue
      end
    end
    Dir['**/locale.yml'].each do |file|
      files[file] = File.read(file)
    end

    files.each do |file, content|
      puts "Checking #{file}"
      translations = YAML.load(content)
      en = translations['en']
      raise 'en locale missing' unless en
      en_keys = en.keys
      translations.each do |locale,hash|
        delta = hash.keys - en_keys
        puts "\t#{locale} has additional keys #{delta.join(' ')}" unless delta.empty?
        delta = en_keys - hash.keys
        puts "\t#{locale} is missing the keys #{delta.join(' ')}" unless delta.empty?
        (en_keys & hash.keys).each do |key|
          if hash[key].count('%{') != en[key].count('%{')
            puts "\t#{locale}:#{key} has invalid number of arguments"
          end
        end
      end
    end
  end
end

namespace :notes do
  task :todo      do; system('ack T''ODO');      end
  task :fixme     do; system('ack F''IXME');     end
  task :hack      do; system('ack H''ACK');      end
  task :warn      do; system('ack W''ARN');      end
  task :important do; system('ack I''MPORTANT'); end
end

desc 'Show annotations'
task notes: %w(notes:todo notes:fixme notes:hack notes:warn notes:important)
