module Olelo
  class VirtualFS
    def read(name)
      raise NotImplementedError
    end

    def glob(*names)
      raise NotImplementedError
    end

    def mtime(name)
      raise NotImplementedError
    end

    def open(name)
      [read(name)]
    end

    def size(name)
      read(name).bytesize
    end

    def mime(name)
      MimeMagic.by_path(name) || MimeMagic.new('application/octet-stream')
    end

    class VirtualFile
      attr_reader :fs, :name

      def initialize(fs, name)
        @fs, @name = fs, name
      end

      def read
        fs.read(name)
      end

      def open
        fs.open(name)
      end

      def mtime
        @mtime ||= fs.mtime(name)
      end

      def size
        @size ||= fs.size(name)
      end

      def mime
        @fs.mime(name)
      end
    end

    class Native < VirtualFS
      def initialize(dir)
        @dir = dir
      end

      # @override
      def read(name)
        File.read(File.join(@dir, name))
      end

      # @override
      def glob(*names)
        names.map do |name|
          Dir[File.join(@dir, name)].select {|f| File.file?(f) }
        end.flatten.each do |f|
          yield(VirtualFile.new(self, f[@dir.length+1..-1]))
        end
      end

      # @override
      def open(name)
        BlockFile.open(File.join(@dir, name), 'rb')
      end

      # @override
      def mtime(name)
        File.mtime(File.join(@dir, name))
      end

      # @override
      def size(name)
        File.stat(File.join(@dir, name)).size
      end
    end

    class Embedded < VirtualFS
      def initialize(file)
        @file = file
        @cache = {}
      end

      # @override
      def read(name)
        @cache[name] ||=
          begin
            code, data = File.read(@file).split('__END__')
            content = nil
            data.to_s.each_line do |line|
            if line =~ /^@@\s*([^\s]+)\s*/
              if name == $1
                content = ''
              elsif content
                break
              end
            elsif content
              content << line
            end
          end
            content || raise(IOError, "#{name} not found")
          end
      end

      # @override
      def glob(*names)
        code, data = File.read(@file).split('__END__')
        data.to_s.each_line do |line|
          if line =~ /^@@\s*([^\s]+)\s*/ && names.any? {|pattern| File.fnmatch(pattern, $1) }
            yield(VirtualFile.new(self, $1))
          end
        end
      end

      # @override
      def mtime(name)
        File.mtime(@file)
      end
    end

    class Union < VirtualFS
      def initialize(*fs)
        @fs = fs.compact
      end

      # @override
      def glob(*names, &block)
        @fs.each {|fs| fs.glob(*names, &block) }
      end

      %w(read mtime open size mime).each do |method|
        class_eval %{
          def #{method}(*args)
            result = nil
            @fs.any? do |fs|
              begin
                result = fs.#{method}(*args)
              rescue
              end
            end || raise(IOError, "#{method}(\#{args.map(&:inspect).join(', ')}) failed")
            result
          end
        }
      end

    end

  end
end
