require 'formula'

class Xpra < Formula
  homepage 'http://xpra.org'
  url 'http://winswitch.org/src/xpra-0.10.9.tar.bz2'
  sha1 '1fe8113242143d51f492502e1d0c7441c34cbf23'
  head 'http://xpra.org/svn/Xpra/trunk/src/', :using => :svn

  # We want pkg-config
  env :userpaths

  depends_on :python
  depends_on 'Cython' => :python
  # PyObjC is used for AppKit - install core first to avoid recompilation
  depends_on 'pyobjc-core' => :python
  depends_on 'pyobjc' => :python
  # PyOpenGL is only required if pygtkglext is to be used
  depends_on 'OpenGL' => :python if build.with? 'pygtkglext'
  depends_on 'OpenGL_accelerate' => :python if build.with? 'pygtkglext'
  depends_on :x11
  depends_on 'pygtk'
  depends_on 'pygtkglext' => :recommended
  depends_on 'ffmpeg'
  depends_on 'libvpx'
  depends_on 'webp'
  depends_on 'xz'

  def patches
    # Do not depend on gtkosx_application / gtk-mac-integration library,
    # as this requires the Gtk Quartz backend which is unavailable on brew.
    # Use AppKit NSBeep instead of Carbon.Snd.SysBeep for system bell.
    # Fix icon directory.
    DATA
  end

  def install
    system "python", "setup.py", "install", "--prefix=#{prefix}"
  end
end

__END__
diff --git a/xpra/platform/darwin/gui.py b/xpra/platform/darwin/gui.py
index 14f0b20..1abbc81 100644
--- a/xpra/platform/darwin/gui.py
+++ b/xpra/platform/darwin/gui.py
@@ -48,6 +48,8 @@ except:
 
 def do_init():
     osxapp = get_OSXApplication()
+    if not osxapp:
+        return
     icon = get_icon("xpra.png")
     if icon:
         osxapp.set_dock_icon_pixbuf(icon)
@@ -58,6 +60,8 @@ def do_init():
 
 def do_ready():
     osxapp = get_OSXApplication()
+    if not osxapp:
+        return
     osxapp.ready()
 
 

diff --git a/xpra/platform/darwin/osx_tray.py b/xpra/platform/darwin/osx_tray.py
index 0bccf89..b62963c 100644
--- a/xpra/platform/darwin/osx_tray.py
+++ b/xpra/platform/darwin/osx_tray.py
@@ -51,6 +51,8 @@ class OSXTray(TrayBase):
         pass
 
     def set_blinking(self, on):
+        if not self.macapp:
+            return
         if on:
             if self.last_attention_request_id<0:
                 self.last_attention_request_id = self.macapp.attention_request(INFO_REQUEST)
@@ -60,6 +62,8 @@ class OSXTray(TrayBase):
                 self.last_attention_request_id = -1
 
     def set_icon_from_data(self, pixels, has_alpha, w, h, rowstride):
+        if not self.macapp:
+            return
         tray_icon = gtk.gdk.pixbuf_new_from_data(pixels, gtk.gdk.COLORSPACE_RGB, has_alpha, 8, w, h, rowstride)
         self.macapp.set_dock_icon_pixbuf(tray_icon)
 
@@ -77,7 +81,8 @@ class OSXTray(TrayBase):
             return
         #redundant: the menu bar has already been set during gui init
         #using the basic the simple menu from build_menu_bar()
-        self.macapp.set_menu_bar(self.menu)
+        if self.macapp:
+            self.macapp.set_menu_bar(self.menu)
         mh.add_full_menu()
         debug("OSXTray.set_global_menu() done")
 
@@ -89,7 +94,8 @@ class OSXTray(TrayBase):
         self.disconnect_dock_item.connect("activate", self.quit)
         self.dock_menu.add(self.disconnect_dock_item)
         self.dock_menu.show_all()
-        self.macapp.set_dock_menu(self.dock_menu)
+        if self.macapp:
+            self.macapp.set_dock_menu(self.dock_menu)
         debug("OSXTray.set_dock_menu() done")
 
     def set_dock_icon(self):
# Currently this is only used by HEAD
# @@ -101,4 +107,5 @@ class OSXTray(TrayBase):
#              return
#          debug("OSXTray.set_dock_icon() loading icon from %s", filename)
#          pixbuf = gtk.gdk.pixbuf_new_from_file(filename)
# -        self.macapp.set_dock_icon_pixbuf(pixbuf)
# +        if self.macapp:
# +            self.macapp.set_dock_icon_pixbuf(pixbuf)
diff --git a/xpra/platform/darwin/gui.py b/xpra/platform/darwin/gui.py
index 1abbc81..08861e0 100644
--- a/xpra/platform/darwin/gui.py
+++ b/xpra/platform/darwin/gui.py
@@ -41,9 +41,13 @@ def get_OSXApplication():
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
@@ -73,7 +77,10 @@ def get_native_tray_classes():
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
diff --git a/xpra/platform/darwin/paths.py b/xpra/platform/darwin/paths.py
index 5410525..e845cc8 100644
--- a/xpra/platform/darwin/paths.py
+++ b/xpra/platform/darwin/paths.py
@@ -47,4 +47,9 @@ def get_app_dir():
 
 def get_icon_dir():
     rsc = get_resources_dir()
-    return os.path.join(rsc, "share", "xpra", "icons")
+    head, tail = os.path.split(rsc)
+    headhead, headtail = os.path.split(head)
+    if headtail == "share" and tail == "xpra":
+        return os.path.join(rsc, "icons")
+    else:
+        return os.path.join(rsc, "share", "xpra", "icons")
