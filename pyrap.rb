require 'formula'

class Pyrap < Formula
  homepage 'http://code.google.com/p/pyrap/'
  url 'http://pyrap.googlecode.com/files/pyrap-1.1.0.tar.bz2'
  sha1 '8901071b09f747f0a210f180f91869e020c9d081'
  head 'http://pyrap.googlecode.com/svn/trunk'

  depends_on 'scons' => :build
  depends_on 'boost'
  depends_on 'casacore'
  depends_on :python => ['numpy']

  def patches
    p = []
    # Patch to support compilation on Mac OS 10.7+ (Lion and up) by ignoring sysroot
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/da9264e50c244b84cd92e180b207e13928f7ff93/patch1.diff'
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/c0981d0c27b3086cb7378cf4442b2754abc8a42d/patch2.diff' if build.head?
    # Patch to ignore fortran to c library (aka libgfortran)
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/0bda200fb5c8f743c488077e94195c786ecb2486/patch3.diff'
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/5bdd5e6ab42e9551750128c441a775dffaa3feea/patch4.diff' if build.head?
    # Patch to disable explicit linking to system Python framework in order to support brew Python (and other non-system versions)
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/0dbf63fba7b4caed537c84eb26c42afc7db0ec23/patch5.diff' if not build.head?
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/a270c600a5870523192a791c6a4459bbddc293b3/patch6.diff' if build.head?
    return p.empty? ? nil : p
  end

  def install
    if build.head?
      build_cmd = 'batchbuild-trunk.py'
    else
      build_cmd = 'batchbuild.py'
    end
    system python, "#{build_cmd}",
           "--boost-root=#{HOMEBREW_PREFIX}", "--boost-lib=boost_python-mt",
           "--enable-hdf5", "--prefix=#{prefix}",
           "--python-prefix=#{python.site_packages}",
           "--universal=x86_64"
    # Get rid of horrible eggs as they trample on other packages via site.py and easy-install.pth
    cd "#{python.site_packages}"
    rm_f ['easy-install.pth', 'site.py', 'site.pyc']
    mkdir 'pyrap'
    touch 'pyrap/__init__.py'
    Dir['pyrap.*.egg'].each do |egg|
      Dir.foreach("#{egg}/pyrap") do |item|
        next if ['.', '..', '__init__.py', '__init__.pyc'].include? item
        mv "#{egg}/pyrap/#{item}", 'pyrap/'
      end
      rm_rf egg
    end
  end
  
  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{python.global_site_packages}:$PYTHONPATH
    EOS
  end
end
