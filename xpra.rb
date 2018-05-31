class Xpra < Formula
  desc 'Multi-platform screen and application forwarding system: "screen for X11"'
  homepage "http://xpra.org"
  url "https://www.xpra.org/src/xpra-0.17.6.tar.bz2"
  sha256 "d08a68802f86183e69c7bcb2b6c42dc93fce60d2d017beb9a1b18f581f8902d2"
  head "http://xpra.org/svn/Xpra/trunk/src/", :using => :svn

  # We want pkg-config
  env :userpaths

  depends_on 'python@2'
  depends_on "Cython"
  # PyObjC is used for AppKit - install core first to avoid recompilation
  # Missing dependencies: objc
  # PyOpenGL is only required if pygtkglext is to be used
  depends_on "OpenGL" if build.with? "pygtkglext"
  depends_on "OpenGL_accelerate" if build.with? "pygtkglext"
  depends_on :x11
  depends_on "pygtk"
  depends_on "pygtkglext" => :recommended
  depends_on "gtk-mac-integration"
  depends_on "ffmpeg"
  depends_on "libvpx"
  depends_on "webp"
  # extras: rencode cryptography lzo lz4

  # 1) Use AppKit NSBeep instead of Carbon.Snd.SysBeep for system bell.
  # 2) Fix icon directory.
  patch :DATA

  def install
    inreplace "xpra/platform/paths.py", "sys.prefix", '"#{prefix}"'
    system "python", "setup.py", "install", "--prefix=#{prefix}"
  end

  test do
    system "#{bin}/xpra", "showconfig"
  end
end

__END__
diff --git a/xpra/platform/darwin/gui.py b/xpra/platform/darwin/gui.py
index 52f0c6b..05fd0ec 100644
--- a/xpra/platform/darwin/gui.py
+++ b/xpra/platform/darwin/gui.py
@@ -39,9 +39,13 @@ def get_OSXApplication():
     return macapp
 
 try:
-    from Carbon import Snd      #@UnresolvedImport
+    from AppKit import NSBeep       #@UnresolvedImport
 except:
-    Snd = None
+    NSBeep = None
+    try:
+        from Carbon.Snd import SysBeep     #@UnresolvedImport
+    except:
+        SysBeep = None
 
 
 def do_init():
@@ -75,10 +81,13 @@ def get_native_tray_classes():
     return [OSXTray]
 
 def system_bell(*args):
-    if Snd is None:
-        return False
-    Snd.SysBeep(1)
-    return True
+    if NSBeep is not None:
+        NSBeep()
+        return True
+    if SysBeep is not None:
+        SysBeep(1)
+        return True
+    return False
 
 #if there is an easier way of doing this, I couldn't find it:
 try:
diff --git a/xpra/platform/darwin/paths.py b/xpra/platform/darwin/paths.py
index 0f7137d..67990f3 100644
--- a/xpra/platform/darwin/paths.py
+++ b/xpra/platform/darwin/paths.py
@@ -18,7 +18,7 @@ def do_get_resources_dir():
     RESOURCES = "/Resources/"
     #FUGLY warning: importing gtkosx_application causes the dock to appear,
     #and in some cases we don't want that.. so use the env var XPRA_SKIP_UI as workaround for such cases:
-    if os.environ.get("XPRA_SKIP_UI", "0")=="0":
+    if os.environ.get("XPRA_SKIP_UI", "1")=="0":
         try:
             import gtkosx_application        #@UnresolvedImport
             try:
diff --git a/xpra/platform/darwin/paths.py b/xpra/platform/darwin/paths.py
index f9ac98e..0f7137d 100644
--- a/xpra/platform/darwin/paths.py
+++ b/xpra/platform/darwin/paths.py
@@ -61,7 +61,13 @@ def do_get_app_dir():
 
 def do_get_icon_dir():
     from xpra.platform.paths import get_resources_dir
-    i = os.path.join(get_resources_dir(), "share", "xpra", "icons")
+    rsc = get_resources_dir()
+    head, tail = os.path.split(rsc)
+    headhead, headtail = os.path.split(head)
+    if headtail == "share" and tail == "xpra":
+        i = os.path.join(rsc, "icons")
+    else:
+        i = os.path.join(rsc, "share", "xpra", "icons")
     debug("get_icon_dir()=%s", i)
     return i
 
