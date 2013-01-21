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
    DATA
  end

  def install
    # ENV.j1  # if your formula's build system can't parallelize

    system "python", "batchbuild.py",
           "--boost-root=#{HOMEBREW_PREFIX}", "--boost-lib=boost_python-mt",
           "--enable-hdf5", "--prefix=#{prefix}",
           "--python-prefix=#{lib}/#{which_python}/site-packages",
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

__END__
Patch to support compilation on Mac OS 10.7 (Lion) by ignoring sysroot.

diff --git a/batchbuild.py b/batchbuild.py
index 2af88a6..2b9cbf1 100755
--- a/batchbuild.py
+++ b/batchbuild.py
@@ -5,7 +5,6 @@ import os
 import glob
 import shutil
 import re
-import string
 import optparse
 import subprocess
 
@@ -22,9 +21,10 @@ def darwin_sdk(archlist=None):
     if version[0] != '10' or int(version[1]) < 4:
         print "Only Mac OS X >= 10.4 is supported"
         sys.exit(1)
-    sdk = string.join([""]+archlist.split(","), " -arch ")
-    sdk += " -isysroot %s" % devpath[version[1]]
-    return (string.join(version[:2],"."), sdk)
+    sdk = " -arch ".join([""] + archlist.split(","))
+    if int(version[1]) < 7:
+        sdk += " -isysroot %s" % devpath[version[1]]
+    return (".".join(version[:2]), sdk)
 
 
 usage = "usage: %prog [options] <packagename>"
diff --git a/libpyrap/tags/pyrap-0.3.2/scons-tools/utils.py b/libpyrap/tags/pyrap-0.3.2/scons-tools/utils.py
index fb87b5e..da1a0fc 100644
--- a/libpyrap/tags/pyrap-0.3.2/scons-tools/utils.py
+++ b/libpyrap/tags/pyrap-0.3.2/scons-tools/utils.py
@@ -225,9 +225,15 @@ def generate(env):
             if uniarch:
                 for i in uniarch.split(','):            
                     flags += ['-arch', i]
-                ppflags =  flags + ['-isysroot' , env.DarwinDevSdk() ]
-                linkflags = flags + ['-Wl,-syslibroot,%s'\
-                                         %  env.DarwinDevSdk()]
+                import platform
+                version = platform.mac_ver()[0].split(".")
+                if int(version[1]) < 7:
+                    ppflags =  flags + ['-isysroot' , env.DarwinDevSdk() ]
+                    linkflags = flags + ['-Wl,-syslibroot,%s'\
+                                             %  env.DarwinDevSdk()]
+                else:
+                    ppflags = flags
+                    linkflags = flags
                 env.Append(CPPFLAGS=ppflags)
                 env.Append(SHLINKFLAGS=linkflags)
                 env.Append(LINKFLAGS=linkflags)

Patch to ignore fortran to c library (aka libgfortran)

diff --git a/pyrap_fitting/tags/pyrap_fitting-0.2.1/setupext.py b/pyrap_fitting/tags/pyrap_fitting-0.2.1/setupext.py
index 82428c6..3d21b61 100644
--- a/pyrap_fitting/tags/pyrap_fitting-0.2.1/setupext.py
+++ b/pyrap_fitting/tags/pyrap_fitting-0.2.1/setupext.py
@@ -121,7 +121,7 @@ class casacorebuild_ext(build_ext.build_ext):
 	self.libraries += [self.boostlib]
 	self.libraries += self.blaslib.split(",")
 	self.libraries += self.lapacklib.split(",")
-        self.libraries += [self.f2clib]
+#        self.libraries += [self.f2clib]
 
         if self.enable_hdf5:
             hdf5libdir = os.path.join(self.hdf5, ARCHLIBDIR)
diff --git a/pyrap_functionals/tags/pyrap_functionals-0.2.1/setupext.py b/pyrap_functionals/tags/pyrap_functionals-0.2.1/setupext.py
index 82428c6..3d21b61 100644
--- a/pyrap_functionals/tags/pyrap_functionals-0.2.1/setupext.py
+++ b/pyrap_functionals/tags/pyrap_functionals-0.2.1/setupext.py
@@ -121,7 +121,7 @@ class casacorebuild_ext(build_ext.build_ext):
 	self.libraries += [self.boostlib]
 	self.libraries += self.blaslib.split(",")
 	self.libraries += self.lapacklib.split(",")
-        self.libraries += [self.f2clib]
+#        self.libraries += [self.f2clib]
 
         if self.enable_hdf5:
             hdf5libdir = os.path.join(self.hdf5, ARCHLIBDIR)
diff --git a/pyrap_images/tags/pyrap_images-0.1.1/setupext.py b/pyrap_images/tags/pyrap_images-0.1.1/setupext.py
index 34abb7c..903c7a4 100644
--- a/pyrap_images/tags/pyrap_images-0.1.1/setupext.py
+++ b/pyrap_images/tags/pyrap_images-0.1.1/setupext.py
@@ -136,7 +136,7 @@ class casacorebuild_ext(build_ext.build_ext):
 	self.libraries += [self.cfitsiolib]
 	self.libraries += self.blaslib.split(",")
 	self.libraries += self.lapacklib.split(",")
-	self.libraries += [self.f2clib]
+#	self.libraries += [self.f2clib]
 
         if self.enable_hdf5:
             if hdf5libdir not in self.library_dirs:
diff --git a/pyrap_measures/tags/pyrap_measures-0.2.1/setupext.py b/pyrap_measures/tags/pyrap_measures-0.2.1/setupext.py
index 82428c6..3d21b61 100644
--- a/pyrap_measures/tags/pyrap_measures-0.2.1/setupext.py
+++ b/pyrap_measures/tags/pyrap_measures-0.2.1/setupext.py
@@ -121,7 +121,7 @@ class casacorebuild_ext(build_ext.build_ext):
 	self.libraries += [self.boostlib]
 	self.libraries += self.blaslib.split(",")
 	self.libraries += self.lapacklib.split(",")
-        self.libraries += [self.f2clib]
+#        self.libraries += [self.f2clib]
 
         if self.enable_hdf5:
             hdf5libdir = os.path.join(self.hdf5, ARCHLIBDIR)
