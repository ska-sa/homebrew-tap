require 'formula'

class Purr < Formula
  homepage 'http://www.astron.nl/meqwiki/Purr/Introduction'
  url 'https://svn.astron.nl/Purr/release/Purr/release-1.2.0'
  head 'https://svn.astron.nl/Purr/trunk/Purr'

  depends_on 'pyqt'
  depends_on 'pyfits' => :python

  def patches
    # First look for icons in meqtrees share directory
    DATA
  end

  def install
    mkdir_p "#{lib}/#{which_python}/site-packages"
    cp_r ['Purr', 'Kittens'], "#{lib}/#{which_python}/site-packages/"
    mkdir_p "#{share}/meqtrees"
    cp_r 'icons', "#{share}/meqtrees/"
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end

  def test
    if system 'python -c "import Purr"' then
      onoe 'Purr FAILED'
    else
      ohai 'Purr OK'
    end
  end
end

__END__
diff --git a/Kittens/pixmaps.py b/Kittens/pixmaps.py
index f136a5b..a1f5db4 100644
--- a/Kittens/pixmaps.py
+++ b/Kittens/pixmaps.py
@@ -3087,7 +3087,8 @@ class PixmapCache (object):
     # loop over system path
     if self._loaded:
       return;
-    for path in sys.path:
+    icon_paths = ['/usr/local/share/meqtrees'] + sys.path
+    for path in icon_paths:
       path = path or '.';
       # for each entry, try <entry>/icons/<appname>'
       trydir = os.path.join(path,'icons',self._appname);
