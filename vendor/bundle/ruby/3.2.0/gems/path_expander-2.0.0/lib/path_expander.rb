##
# PathExpander helps pre-process command-line arguments expanding
# directories into their constituent files. It further helps by
# providing additional mechanisms to make specifying subsets easier
# with path subtraction and allowing for command-line arguments to be
# saved in a file.
#
# NOTE: this is NOT an options processor. It is a path processor
# (basically everything else besides options). It does provide a
# mechanism for pre-filtering cmdline options, but not with the intent
# of actually processing them in PathExpander. Use OptionParser to
# deal with options either before or after passing ARGV through
# PathExpander.

class PathExpander
  VERSION = "2.0.0" # :nodoc:

  ##
  # The args array to process.

  attr_accessor :args

  ##
  # The glob used to expand dirs to files.

  attr_accessor :glob

  ##
  # The path to scan if no paths are found in the initial scan.

  attr_accessor :path

  ##
  # Create a new path expander that operates on args and expands via
  # glob as necessary. Takes an optional +path+ arg to fall back on if
  # no paths are found on the initial scan (see #process_args).

  def initialize args, glob, path = "."
    self.args = args
    self.glob = glob
    self.path = path
  end

  ##
  # Takes an array of paths and returns an array of paths where all
  # directories are expanded to all files found via the glob provided
  # to PathExpander.
  #
  # Paths are normalized to not have a leading "./".

  def expand_dirs_to_files *dirs
    dirs.flatten.map { |p|
      if File.directory? p then
        Dir[File.join(p, glob)].find_all { |f| File.file? f }
      else
        p
      end
    }.flatten.sort.map { |s| s.to_s.delete_prefix "./" }
  end

  ##
  # Process a file into more arguments. Override this to add
  # additional capabilities.

  def process_file path
    File.readlines(path).map(&:chomp)
  end

  ##
  # Enumerate over args passed to PathExpander and return a list of
  # files and flags to process. Arguments are processed as:
  #
  # @file_of_args :: Read the file and append to args.
  # -file_path    :: Subtract path from file to be processed.
  # -dir_path     :: Expand and subtract paths from files to be processed.
  # -not_a_path   :: Add to flags to be processed.
  # dir_path      :: Expand and add to files to be processed.
  # file_path     :: Add to files to be processed.
  # -             :: Add "-" (stdin) to files to be processed.
  #
  # See expand_dirs_to_files for details on how expansion occurs.
  #
  # Subtraction happens last, regardless of argument ordering.
  #
  # If no files are found (which is not the same as having an empty
  # file list after subtraction), then fall back to expanding on the
  # default #path given to initialize.

  def process_args
    pos_files = []
    neg_files = []
    flags     = []
    clean     = true

    args.each do |arg|
      case arg
      when /^@(.*)/ then # push back on, so they can have dirs/-/@ as well
        clean = false
        args.concat process_file $1
      when "-" then
        pos_files << arg
      when /^-(.*)/ then
        if File.exist? $1 then
          clean = false
          neg_files += expand_dirs_to_files($1)
        else
          flags << arg
        end
      else
        root_path = File.expand_path(arg) == "/" # eg: -n /./
        if File.exist? arg and not root_path then
          clean = false
          pos_files += expand_dirs_to_files(arg)
        else
          flags << arg
        end
      end
    end

    files = pos_files - neg_files
    files += expand_dirs_to_files(self.path) if files.empty? && clean

    [files, flags]
  end

  ##
  # Process over flags and treat any special ones here. Returns an
  # array of the flags you haven't processed.
  #
  # This version does nothing. Subclass and override for
  # customization.

  def process_flags flags
    flags
  end

  ##
  # Top-level method processes args. If no block is given, immediately
  # returns with an Enumerator for further chaining.
  #
  # Otherwise, it calls +pre_process+, +process_args+ and
  # +process_flags+, enumerates over the files, and then calls
  # +post_process+, returning self for any further chaining.
  #
  # Most of the time, you're going to provide a block to process files
  # and do nothing more with the result. Eg:
  #
  #     PathExpander.new(ARGV).process do |f|
  #       puts "./#{f}"
  #     end
  #
  # or:
  #
  #     PathExpander.new(ARGV).process # => Enumerator

  def process(&b)
    return enum_for(:process) unless block_given?

    pre_process

    files, flags = process_args

    args.replace process_flags flags

    files.uniq.each(&b)

    post_process

    self
  end

  def pre_process = nil
  def post_process = nil

  ##
  # A file filter mechanism similar to, but not as extensive as,
  # .gitignore files:
  #
  # + If a pattern does not contain a slash, it is treated as a shell glob.
  # + If a pattern ends in a slash, it matches on directories (and contents).
  # + Otherwise, it matches on relative paths.
  #
  # File.fnmatch is used throughout, so glob patterns work for all 3 types.
  #
  # Takes a list of +files+ and either an io or path of +ignore+ data
  # and returns a list of files left after filtering.

  def filter_files files, ignore
    ignore_paths = if ignore.respond_to? :read then
                     ignore.read
                   elsif File.exist? ignore then
                     File.read ignore
                   end

    if ignore_paths then
      nonglobs, globs = ignore_paths.split("\n").partition { |p| p.include? "/" }
      dirs, ifiles    = nonglobs.partition { |p| p.end_with? "/" }
      dirs            = dirs.map { |s| s.chomp "/" }

      dirs.map!   { |i| File.expand_path i }
      globs.map!  { |i| File.expand_path i }
      ifiles.map! { |i| File.expand_path i }

      only_paths = File::FNM_PATHNAME
      files = files.reject { |f|
        f = File.expand_path(f)
        dirs.any?     { |i| File.fnmatch?(i, File.dirname(f), only_paths) } ||
          globs.any?  { |i| File.fnmatch?(i, f) } ||
          ifiles.any? { |i| File.fnmatch?(i, f, only_paths) }
      }
    end

    files
  end
end
