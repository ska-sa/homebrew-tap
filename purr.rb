require 'formula'

class Purr < Formula
  homepage 'http://www.astron.nl/meqwiki/Purr/Introduction'
  url 'https://svn.astron.nl/Purr/release/Purr/release-1.2.0'
  head 'https://svn.astron.nl/Purr/trunk/Purr'

  depends_on 'pyqt'
  depends_on 'pyfits' => :python

  def patches
    # First look for icons in meqtrees share directory
    # Provide alternatives for Linux-only 'cp -u' and 'mv -u'
    DATA
  end

  def install
    bin.install 'Purr/purr.py', 'Purr/purr'
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
index f136a5b..422cf68 100644
--- a/Kittens/pixmaps.py
+++ b/Kittens/pixmaps.py
@@ -3020,7 +3020,8 @@ def load_icons (appname):
   global __icons_loaded;
   if __icons_loaded:
     return;
-  for path in sys.path:
+  icon_paths = ['/usr/local/share/meqtrees'] + sys.path
+  for path in icon_paths:
     path = path or '.';
     # for each entry, try <entry>/icons/<appname>'
     trydir = os.path.join(path,'icons',appname);
@@ -3087,7 +3088,8 @@ class PixmapCache (object):
     # loop over system path
     if self._loaded:
       return;
-    for path in sys.path:
+    icon_paths = ['/usr/local/share/meqtrees'] + sys.path
+    for path in icon_paths:
       path = path or '.';
       # for each entry, try <entry>/icons/<appname>'
       trydir = os.path.join(path,'icons',self._appname);
diff --git a/Purr/LogEntry.py b/Purr/LogEntry.py
index a7eb82f..9609d3f 100644
--- a/Purr/LogEntry.py
+++ b/Purr/LogEntry.py
@@ -12,6 +12,23 @@ import Purr.Render
 import Purr.RenderIndex
 from Purr.Render import quote_url
 
+
+def _copy_update(sourcepath, destname):
+  """Copy source to dest only if source is newer."""
+  if sys.platform.startswith('linux'):
+    return os.system("/bin/cp -ua '%s' '%s'"%(sourcepath,destname))
+  else:
+    return os.system("rsync -ua '%s' '%s'"%(sourcepath,destname))
+
+
+def _move_update(sourcepath, destname):
+  """Move source to dest only if source is newer."""
+  if sys.platform.startswith('linux'):
+    return os.system("/bin/mv -fu '%s' '%s'"%(sourcepath,destname))
+  else:
+    return os.system("rsync -ua --remove-source-files '%s' '%s'"%(sourcepath,destname))
+
+
 class DataProduct (object):
   def __init__ (self,filename=None,sourcepath=None,fullpath=None,
       policy="copy",comment="",
@@ -328,12 +345,12 @@ class LogEntry (object):
         # now copy/move it over
         if dp.policy == "copy":
           dprintf(2,"copying\n");
-          if os.system("/bin/cp -ua '%s' '%s'"%(sourcepath,destname)):
+          if _copy_update(sourcepath,destname):
             print "Error copying %s to %s"%(sourcepath,destname);
             print "This data product is not saved.";
             continue;
         elif dp.policy.startswith('move'):
-          if os.system("/bin/mv -fu '%s' '%s'"%(sourcepath,destname)):
+          if _move_update(sourcepath,destname):
             print "Error moving %s to %s"%(sourcepath,destname);
             print "This data product is not saved.";
             continue;
