require 'formula'

class Pyrap < Formula
  homepage 'http://code.google.com/p/pyrap/'
  url 'http://pyrap.googlecode.com/files/pyrap-1.1.0.tar.bz2'
  sha1 '8901071b09f747f0a210f180f91869e020c9d081'
  head 'http://pyrap.googlecode.com/svn/trunk'

  depends_on 'scons' => :build
  depends_on 'boost'
  depends_on 'casacore'

  def patches
    p = []
    # Patch to support compilation on Mac OS 10.7+ (Lion and up) by ignoring sysroot
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/da9264e50c244b84cd92e180b207e13928f7ff93/patch1.diff'
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/c0981d0c27b3086cb7378cf4442b2754abc8a42d/patch2.diff' if build.head?
    # Patch to ignore fortran to c library (aka libgfortran)
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/0bda200fb5c8f743c488077e94195c786ecb2486/patch3.diff'
    p << 'https://gist.github.com/ludwigschwardt/5195760/raw/5bdd5e6ab42e9551750128c441a775dffaa3feea/patch4.diff' if build.head?
    return p.empty? ? nil : p
  end

  def install
    if build.head?
      build_cmd = 'batchbuild-trunk.py'
    else
      build_cmd = 'batchbuild.py'
    end
    python_prefix = "#{lib}/#{which_python}/site-packages"
    system "PYTHONPATH=#{python_prefix}:${PYTHONPATH}",
           "python", "#{build_cmd}",
           "--boost-root=#{HOMEBREW_PREFIX}", "--boost-lib=boost_python-mt",
           "--enable-hdf5", "--prefix=#{prefix}",
           "--python-prefix=#{python_prefix}",
           "--universal=x86_64"
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
