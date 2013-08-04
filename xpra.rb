require 'formula'

class Xpra < Formula
  homepage 'http://xpra.org'
  url 'https://www.xpra.org/src/xpra-0.7.8.tar.bz2'
  sha1 '0f8b433c97b707e555c4b45e6a411c007baebdf8'

  # We want pkg-config
  env :userpaths

  depends_on :python
  depends_on :x11
  depends_on 'pygtk'
  depends_on 'ffmpeg'
  depends_on 'libvpx'
  depends_on 'webp'
  depends_on 'Cython' => :python

  def patches
    # 1. Fix pygtk include directory
    DATA
  end

  def install
    python do
      system python, "setup.py", "install", "--prefix=#{prefix}"
    end
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{python.global_site_packages}:$PYTHONPATH
    EOS
  end
end

__END__
diff --git a/wimpiggy/gdk/gdk_atoms.pyx b/wimpiggy/gdk/gdk_atoms.pyx
index 900aa66..0a1392f 100644
--- a/wimpiggy/gdk/gdk_atoms.pyx
+++ b/wimpiggy/gdk/gdk_atoms.pyx
@@ -23,7 +23,7 @@ cdef extern from "pygobject.h":
     void init_pygobject()
 init_pygobject()
 
-cdef extern from "pygtk/pygtk.h":
+cdef extern from "pygtk-2.0/pygtk/pygtk.h":
     void init_pygtk()
 init_pygtk()
 # Now all the macros in those header files will work.
