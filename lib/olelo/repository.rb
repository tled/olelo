module Olelo
  # Version object
  class Version
    attr_reader :id, :author, :date, :comment, :parents
    attr_reader? :head

    def initialize(id, author, date, comment, parents, head)
      @id, @author, @date, @comment, @parents, @head = id, author, date, comment, parents, head
    end

    # Returns shortened unique version id
    #
    # @return [String] shortened version id
    # @api public
    def short
      Version.short(id)
    end

    # Shortens given version id
    #
    # @param [String] long version id
    # @return [String] shortened version id
    # @api public
    def self.short(id)
      Repository.instance.short_version(id)
    end

    # Return version id
    #
    # @return [String]
    # @api public
    def to_s
      id
    end

    # Check equality of versions
    #
    # @param [Version, String] other version
    # @return [Boolean]
    # @api public
    def ==(other)
      other.to_s == id
    end
  end

  # Difference between versions
  Diff = Struct.new(:from, :to, :patch)

  # Abstract repository base
  #
  # This class should not be used directly. Use the {Page} class
  # which is implemented on top of it.
  #
  # @abstract
  class Repository
    include Util
    extend Factory

    def self.instance
      Thread.current[:olelo_repository] ||= self[Config['repository.type']].new(Config['repository'][Config['repository.type']])
    end

    # Wrap block in transaction
    #
    # Every write operation has to be wrapped in a transaction.
    #
    # @yield Transaction block
    # @return [void]
    # @api public
    def transaction
      raise NotImplementedError
    end

    # Set content of path
    #
    # This method can only be used within a {#transaction} block.
    #
    # @param [String] path
    # @param [String, #read] content
    # @return [void]
    # @api public
    def set_content(path, content)
      raise NotImplementedError
    end

    # Set attributes of path
    #
    # This method can only be used within a {#transaction} block.
    #
    # @param [String] path
    # @param [Hash] attributes
    # @return [void]
    # @api public
    def set_attributes(path, attributes)
      raise NotImplementedError
    end

    # Move path
    #
    # This method can only be used within a {#transaction} block.
    #
    # @param [String] path
    # @param [String] destination
    # @return [void]
    def move(path, destination)
      raise NotImplementedError
    end

    # Delete path
    #
    # This method can only be used within a {#transaction} block.
    #
    # @param [String] path
    # @return [void]
    def delete(path)
      raise NotImplementedError
    end

    # Commit changes with a comment
    #
    # This method can only be used within a {#transaction} block.
    #
    # @param [String] comment
    # @return [Version] New head version
    # @api public
    def commit(comment)
      raise NotImplementedError
    end

    # Check if path exists and return etag
    #
    # @param [String] path
    # @param [String, Version] version
    # @return [String]
    # @api public
    def path_etag(path, version)
      raise NotImplementedError
    end

    # Find version by version id
    #
    # Returns head version if no version is given
    #
    # @param [String] version
    # @return [Version]
    # @api public
    def get_version(version = nil)
      raise NotImplementedError
    end

    # Get history of path beginning with newest version
    #
    # @param [String] path
    # @param [Integer] Number of versions to skip
    # @param [Integer] Maximum number of versions to load
    # @return [Array<Version>]
    # @api public
    def get_history(path, skip, limit)
      raise NotImplementedError
    end

    # Get versions of path
    #
    # @param [String] path
    # @param [String, Version] version
    # @return [Array<Version>] Tuple: previous version, current version, next version
    # @api public
    def get_path_version(path, version)
      raise NotImplementedError
    end

    # Get children of path
    #
    # @param [String] path
    # @param [String, Version] version
    # @return [Array<String>] Names of children
    # @api public
    def get_children(path, version)
      raise NotImplementedError
    end

    # Get content
    #
    # @param [String] path
    # @param [String, Version] version
    # @return [String] content
    # @api public
    def get_content(path, version)
      raise NotImplementedError
    end

    # Get attributes
    #
    # @param [String] path
    # @param [String, Version] version
    # @return [Hash] attribute hash
    # @api public
    def get_attributes(path, version)
      raise NotImplementedError
    end

    # Difference between versions for path
    #
    # @param [String] path
    # @param [Version, String] from
    # @param [Version, String] to
    # @api public
    def diff(path, from, to)
      raise NotImplementedError
    end

    # Shortens given version id
    #
    # @param [String] long version id
    # @return [String] shortened version id
    # @api public
    def short_version(version)
      version
    end
  end
end
