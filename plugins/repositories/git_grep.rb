description 'Searching via git-grep'

class ::Olelo::Application
  get '/search' do
    @matches = {}

    if params[:pattern].to_s.length > 2
      Repository.instance.git_grep('-z', '-i', '-I', '-3', '-e', params[:pattern], 'master') do |io|
        while !io.eof?
          begin
            line = io.readline.try_encoding(Encoding::UTF_8)
            line = unescape_backslash(line)
            if line =~ /(.*?)\:([^\0]+)\0(.*)/
              path, match = $2, $3
              path = path.split('/')
              path.pop if Repository.instance.reserved_name?(path.last)
              path = path.join('/')
              (@matches[path] ||= []) << match
            end
          rescue => ex
            Olelo.logger.error ex
          end
        end
      end rescue nil # git-grep returns 1 if nothing is found

      Repository.instance.git_ls_tree('-r', '--name-only', 'HEAD') do |io|
        while !io.eof?
          begin
            line = io.readline.try_encoding(Encoding::UTF_8)
            line = unescape_backslash(line).strip
            if line =~ /#{params[:pattern]}/i && !@matches[line]
              path = line.split('/')
              path.pop if Repository.instance.reserved_name?(path.last)
              path = path.join('/')
              page = Page.find!(path)
              @matches[path] = [truncate(page.content, 500)] if page.mime.text?
            end
          rescue => ex
            Olelo.logger.error ex
          end
        end
      end
    end

    @matches = @matches.to_a.sort do |a,b|
      a[1].length == b[1].length ? a[0] <=> b[0] : b[1].length <=> a[1].length
    end.map {|path, content| [path, content.join] }

    render :grep
  end

  private

  def emphasize(s)
    escape_html(truncate(s, 500)).gsub(/(#{params[:pattern]})/i, '<b>\1</b>').html_safe
  end
end

__END__
@@ grep.slim
- title :search_results.t(:pattern => params[:pattern])
h1= title
p= :match.t(:count => @matches.length)
.search
  - @matches.each do |path, content|
    .match
      h2
        a.name href=build_path(path) = emphasize(path)
      .content= emphasize(content)
