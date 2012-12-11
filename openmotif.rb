require 'formula'

class Openmotif < Formula
  url 'http://motif.ics.com/sites/default/files/openmotif-2.3.3.tar.gz'
  homepage 'http://motif.ics.com/'
  md5 'fd27cd3369d6c7d5ef79eccba524f7be'

  depends_on 'pkg-config' => :build
  depends_on :x11

  def patches
    # MacPorts patches
    { :p0 => ['https://trac.macports.org/export/83688/trunk/dports/x11/openmotif/files/patch-uintptr_t-cast.diff',
              'https://trac.macports.org/export/83688/trunk/dports/x11/openmotif/files/patch-lib-Mrm-Makefile.in.diff',
              'https://trac.macports.org/raw-attachment/ticket/30898/patch-demos-programs-periodic-Makefile.in.diff',
              'https://trac.macports.org/raw-attachment/ticket/30898/patch-clients-uil-UilDefI.h.diff']
    }
  end

  fails_with :clang do
    build 421
    cause <<-EOS.undent
      Compilation fails because clang only support weak aliases.
      EOS
  end

  def install
    ENV.deparallelize
    system "./configure", "--disable-dependency-tracking",
    "--prefix=#{prefix}", "--enable-xft", "--enable-jpeg", "--enable-png"
    system "make install"
  end

  def caveats
    <<-EOS.undent
      This formula installs libraries with the same names as the LessTif
      formula in mxcl/master. If OpenMotif is installed, it may break things
      that are linked against LessTif.
    EOS
  end
end
