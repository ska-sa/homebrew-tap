require 'formula'

class Xpra < Formula
  homepage 'http://xpra.org'
  url 'https://www.xpra.org/src/xpra-0.17.6.tar.bz2'
  sha256 'd08a68802f86183e69c7bcb2b6c42dc93fce60d2d017beb9a1b18f581f8902d2'
  head 'http://xpra.org/svn/Xpra/trunk/src/', :using => :svn

  # We want pkg-config
  env :userpaths

  depends_on :python
  depends_on 'Cython' => :python
  # PyObjC is used for AppKit - install core first to avoid recompilation
  depends_on 'objc' => :python
  # PyOpenGL is only required if pygtkglext is to be used
  depends_on 'OpenGL' => :python if build.with? 'pygtkglext'
  depends_on 'OpenGL_accelerate' => :python if build.with? 'pygtkglext'
  depends_on :x11
  depends_on 'pygtk'
  depends_on 'pygtkglext' => :recommended
  depends_on 'ffmpeg'
  depends_on 'libvpx'
  depends_on 'webp'
  # extras: rencode cryptography lzo lz4

  def patches
    # 1) Do not depend on gtkosx_application / gtk-mac-integration library,
    #    as this requires the Gtk Quartz backend which is unavailable on brew.
    # 2) Use AppKit NSBeep instead of Carbon.Snd.SysBeep for system bell.
    # 3) Fix icon directory.
    DATA
  end

  def install
    system "python", "setup.py", "install", "--prefix=#{prefix}"
  end
end

__END__
diff --git a/xpra/platform/darwin/gui.py b/xpra/platform/darwin/gui.py
index 354edd3..52f0c6b 100644
--- a/xpra/platform/darwin/gui.py
+++ b/xpra/platform/darwin/gui.py
@@ -63,6 +63,8 @@ def do_init():
 
 def do_ready():
     osxapp = get_OSXApplication()
+    if not osxapp:
+        return
     osxapp.ready()
 
 
diff --git a/xpra/platform/darwin/osx_tray.py b/xpra/platform/darwin/osx_tray.py
index 9b1ddd7..d028727 100644
--- a/xpra/platform/darwin/osx_tray.py
+++ b/xpra/platform/darwin/osx_tray.py
@@ -54,6 +54,8 @@ class OSXTray(TrayBase):
         pass
 
     def set_blinking(self, on):
+        if not self.macapp:
+            return
         if on:
             if self.last_attention_request_id<0:
                 self.last_attention_request_id = self.macapp.attention_request(INFO_REQUEST)
@@ -63,6 +65,8 @@ class OSXTray(TrayBase):
                 self.last_attention_request_id = -1
 
     def set_icon_from_data(self, pixels, has_alpha, w, h, rowstride):
+        if not self.macapp:
+            return
         tray_icon = gtk.gdk.pixbuf_new_from_data(pixels, gtk.gdk.COLORSPACE_RGB, has_alpha, 8, w, h, rowstride)
         self.macapp.set_dock_icon_pixbuf(tray_icon)
 
@@ -80,7 +84,8 @@ class OSXTray(TrayBase):
             return
         #redundant: the menu bar has already been set during gui init
         #using the basic the simple menu from build_menu_bar()
-        self.macapp.set_menu_bar(self.menu)
+        if self.macapp:
+            self.macapp.set_menu_bar(self.menu)
         mh.add_full_menu()
         log("OSXTray.set_global_menu() done")
 
@@ -92,7 +97,8 @@ class OSXTray(TrayBase):
         self.disconnect_dock_item.connect("activate", self.quit)
         self.dock_menu.add(self.disconnect_dock_item)
         self.dock_menu.show_all()
-        self.macapp.set_dock_menu(self.dock_menu)
+        if self.macapp:
+            self.macapp.set_dock_menu(self.dock_menu)
         log("OSXTray.set_dock_menu() done")
 
     def set_dock_icon(self):
@@ -104,4 +110,5 @@ class OSXTray(TrayBase):
             return
         log("OSXTray.set_dock_icon() loading icon from %s", filename)
         pixbuf = gtk.gdk.pixbuf_new_from_file(filename)
-        self.macapp.set_dock_icon_pixbuf(pixbuf)
+        if self.macapp:
+            self.macapp.set_dock_icon_pixbuf(pixbuf)
diff --git a/xpra/platform/darwin/osx_menu.py b/xpra/platform/darwin/osx_menu.py
index 3839895..f718437 100644
--- a/xpra/platform/darwin/osx_menu.py
+++ b/xpra/platform/darwin/osx_menu.py
@@ -127,7 +127,8 @@ class OSXMenuHelper(GTKTrayMenuBase):
                 item.set_submenu(submenu)
             item.show_all()
             macapp = get_OSXApplication()
-            macapp.insert_app_menu_item(item, 1)
+            if macapp:
+                macapp.insert_app_menu_item(item, 1)
             self.app_menus[label] = item
 
     def add_to_menu_bar(self, label, submenu):
@@ -157,7 +158,8 @@ class OSXMenuHelper(GTKTrayMenuBase):
         item = self.menuitem("About", cb=about)
         item.show_all()
         macapp = get_OSXApplication()
-        macapp.insert_app_menu_item(item, 0)
+        if macapp:
+            macapp.insert_app_menu_item(item, 0)
         self.app_menus["About"] = item
 
 
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
@@ -77,10 +81,13 @@ def get_native_tray_classes():
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
 
