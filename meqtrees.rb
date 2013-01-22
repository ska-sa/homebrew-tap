require 'formula'

class Meqtrees < Formula
  homepage 'http://www.astron.nl/meqwiki/MeqTrees'
  url 'https://svn.astron.nl/MeqTrees/release/Timba/release-1.2.1'
  head 'https://svn.astron.nl/MeqTrees/trunk/Timba'

  option 'enable-debug', 'Enable debug build of MeqTrees as well as debugging symbols'
  option 'without-symbols', 'Remove debugging symbols'

  # Since MeqTrees is still quite experimental we want debug symbols
  # included, which are aggressively stripped out in superenv.
  env :std

  depends_on 'cmake' => :build
  depends_on 'casacore'
  depends_on 'pyrap'
  depends_on 'casarest'
  depends_on 'cfitsio'
  depends_on 'fftw'
  depends_on 'blitz'
  depends_on 'qdbm'
  depends_on 'pyqwt'
  depends_on 'numpy' => :python
  depends_on 'pyfits' => :python
  depends_on 'PIL' => :python
  # The following packages are strictly optional but by including them
  # it is easy to install the whole MeqTrees suite in one go
  # (and it allows testing the whole suite via Batchtest)
  depends_on 'purr'
  depends_on 'tigger'
  depends_on 'cattery'
  depends_on 'owlcat'
  depends_on 'makems'

  def patches
    p = []
    # Added explicit template instantiation and corrected constness
    p << 'https://gist.github.com/raw/4568292/e187cef9d60d4b89293f2d6b93ad9940ccd9c5aa/patch1.diff'
    # Use correct version of strerror_r on the Mac
    p << 'https://gist.github.com/raw/4568292/21ebb9fd3094b18c37555ef1288915036c623c03/patch2.diff'
    # Fixed bug in thread map index
    p << 'https://gist.github.com/raw/4568292/058d009cd7e90f9578d90494b508b96968dddd13/patch3.diff'
    # Add support for Blitz++ 0.10
    p << 'https://gist.github.com/raw/4568292/76627df1f718eceef29fa3e224d2bfee90c3ce06/patch4.diff'
    # Disambiguate Mutex::Lock class (fixed in HEAD)
    p << 'https://gist.github.com/raw/4568292/38983609880a37d0a93d626628d31fbba76accd2/patch5.diff' if not build.head?
    # Suppress compiler warning by using correct format specifier
    p << 'https://gist.github.com/raw/4568292/f978679da33f843a6260d4c7a36f4c021174d32c/patch6.diff' if build.head?
    # Use file-based Unix sockets on the Mac as abstract sockets are Linux-only
    p << 'https://gist.github.com/raw/4568292/c7cb2091dc7b63b55dbe6f810b5a11bd75856be5/patch7.diff'
    # Provide link to Siamese package instead of Cattery to get it included in sidebars of GUI file dialogs
    p << 'https://gist.github.com/raw/4568292/e33ca38600870e932822dbf23378c88993211035/patch8.diff'
    return p.empty? ? nil : p
  end

  fails_with :clang do
    build 421
    cause <<-EOS.undent
      Throws 'allocation of incomplete type' error on DMI::NumArray
      EOS
  end

  def install
    # Hopefully this Python script will be included in MeqTrees repository in future
    if not File.exists? 'h2py.py'
      system 'curl -O http://hg.python.org/cpython/raw-file/1cfe0f50fd0c/Tools/scripts/h2py.py'
    end

    if build.include? 'enable-debug'
      build_type = 'debug'
    elsif build.include? 'without-symbols'
      build_type = 'release'
    else
      build_type = 'relwithdebinfo'
    end
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete '-DCMAKE_BUILD_TYPE=None'
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCMAKE_SHARED_LINKER_FLAGS='-undefined dynamic_lookup'"
    system 'cmake', '../..', *cmake_args
    system "make"

    ohai "make install"
    # The debug symlink tree is the most complete - use as template for all build types
    cd "../../install/symlinked-debug/bin"
    Dir.foreach('.') do |item|
      next if ['.', '..', 'purr.py', 'trut'].include? item
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      bin.install item if File.exists? item
    end

    cd "../lib"
    Dir.foreach('.') do |item|
      next if not item.start_with? 'lib'
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      item.sub! '.so', '.dylib'
      lib.install item if File.exists? item
    end

    cd '../libexec/python/Timba'
    timba = "#{lib}/#{which_python}/site-packages/Timba"
    mkdir_p timba
    # Create DLFCN.py for our system
    quiet_system 'python ../../../../../h2py.py /usr/include/dlfcn.h'
    Dir.foreach('.') do |item|
      next if ['.', '..'].include? item
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      if File.exists? item
        if item.end_with? '.dylib'
          # Move Python extensions to main library directory (as executables also link to them)
          # and symlink them back to module directory with desired .so extension
          lib.install item
          libname = File.basename(item, '.dylib')
          ln_s "#{lib}/#{libname}.dylib", "#{timba}/#{libname}.so"
        else
          cp_r item, timba+'/'
        end
      end
    end

    cd '../icons'
    mkdir_p "#{share}/meqtrees/icons"
    icons = 'treebrowser'
    icons = if File.symlink? icons then File.readlink(icons) else icons end
    cp_r icons, "#{share}/meqtrees/icons/" if File.exists? icons

    # Assemble debug symbol (*.dSYM) files if the build type requires it
    if build_type != 'release'
      cd "#{lib}"
      Dir.foreach('.') do |item|
        next if not item.end_with? '.dylib'
        safe_system 'dsymutil', item
      end
    end
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end
end
