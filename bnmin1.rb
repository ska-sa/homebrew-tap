require 'formula'

class Bnmin1 < Formula
  homepage 'http://www.mrao.cam.ac.uk/~bn204/oof/bnmin1.html'
  url 'http://www.mrao.cam.ac.uk/~bn204/soft/bnmin1-1.11.tar.bz2'
  version '1.11'
  sha1 'a5c690f80d8ed82c97b7370000dcecc11079cc2f'

  depends_on 'boost'
  depends_on 'swig'
  depends_on 'gsl'

  def patches
    # Patch 1: Allow the use of SWIG 2.x for Python bindings
    # Patch 2: Fix naming of static library
    DATA
  end

  def install
    ENV.deparallelize
    ENV.fortran
    # Avoid arithmetic overflow in pda_d1mach.f
    ENV['FFLAGS'] = '-fno-range-check'
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--enable-static"
    system "make install"
  end
end

__END__
diff --git a/pybind/configure b/pybind/configure
index 828ea58..0d06394 100755
--- a/pybind/configure
+++ b/pybind/configure
@@ -15462,9 +15462,9 @@ $as_echo "$swig_version" >&6; }
                         if test -z "$available_patch" ; then
                                 available_patch=0
                         fi
-                        if test $available_major -ne $required_major \
-                                -o $available_minor -ne $required_minor \
-                                -o $available_patch -lt $required_patch ; then
+                        if test $available_major -lt $required_major \
+                                -o $available_major -eq $required_major -a $available_minor -lt $required_minor \
+                                -o $available_major -eq $required_major -a $available_minor -eq $required_minor -a $available_patch -lt $required_patch ; then
                                 { $as_echo "$as_me:${as_lineno-$LINENO}: WARNING: SWIG version >= 1.3.31 is required.  You have $swig_version.  You should look at http://www.swig.org" >&5
 $as_echo "$as_me: WARNING: SWIG version >= 1.3.31 is required.  You have $swig_version.  You should look at http://www.swig.org" >&2;}
                                 SWIG='echo "Error: SWIG version >= 1.3.31 is required.  You have '"$swig_version"'.  You should look at http://www.swig.org" ; false'
diff --git a/bnmin1.pc.in b/bnmin1.pc.in
index 792bc60..f0f6f91 100644
--- a/bnmin1.pc.in
+++ b/bnmin1.pc.in
@@ -6,5 +6,5 @@ includedir=@includedir@
 Name: BNMin1
 Description: B. Nikolic's minimisation library
 Version: @VERSION@
-Libs:  -L${libdir} ${libdir}/libbnmin1.la
+Libs:  -L${libdir} -lbnmin1
 Cflags: -I${includedir} 

