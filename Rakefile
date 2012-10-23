task default: %w(test:spec)

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

namespace :gen do
  desc('Shrink JS files')
  task js: %w(static/script.js plugins/treeview/script.js plugins/misc/fancybox/script.js plugins/editor/markup/script.js)

  desc('Compile CSS files')
  task css: %w(static/themes/atlantis/style.css
                  plugins/treeview/treeview.css
                  plugins/utils/pygments.css
                  plugins/gallery/gallery.css
                  plugins/misc/fancybox/jquery.fancybox.css
                  plugins/blog/blog.css)
end

namespace :test do
  desc 'Run tests with bacon'
  task spec: FileList['test/*_test.rb'] do |t|
    sh "bacon -q -Ilib:test #{t.prerequisites.join(' ')}"
  end

  desc 'Generate test coverage report'
  task rcov: FileList['test/*_test.rb'] do |t|
    sh "rcov -Ilib:test #{t.prerequisites.join(' ')}"
  end
end

desc 'Cleanup'
task :clean do |t|
  FileUtils.rm_rf 'doc/api'
  FileUtils.rm_rf 'coverage'
  FileUtils.rm_rf '.wiki/cache'
  FileUtils.rm_rf '.wiki/blahtex'
  FileUtils.rm_rf '.wiki/log'
end

desc 'Remove wiki folder'
task 'clean:all' => :clean do |t|
  FileUtils.rm_rf '.wiki'
end

desc 'Generate documentation'
namespace :doc do
  task :gen    do; system("yard doc -o doc/api 'lib/**/*.rb' 'plugins/**/*.rb'"); end
  task :server do; system('yard server --reload'); end
  task :check  do; system("yardcheck 'lib/**/*.rb' 'plugins/**/*.rb'"); end
end

namespace :notes do
  task :todo      do; system('ack T''ODO');      end
  task :fixme     do; system('ack F''IXME');     end
  task :hack      do; system('ack H''ACK');      end
  task :warning   do; system('ack W''ARNING');   end
  task :important do; system('ack I''MPORTANT'); end
end

desc 'Show annotations'
task notes: %w(notes:todo notes:fixme notes:hack notes:warning notes:important)
