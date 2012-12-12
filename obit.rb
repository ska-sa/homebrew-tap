require 'formula'

class Obit < Formula
  homepage 'http://www.cv.nrao.edu/~bcotton/Obit.html'
  head 'https://svn.cv.nrao.edu/svn/ObitInstall/ObitSystem/Obit'

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'pkg-config' => :build

  depends_on 'plplot'
  depends_on 'cfitsio'
  depends_on 'glib'
  depends_on 'fftw'
  depends_on 'gsl'
  depends_on 'openmotif'
#  depends_on 'libwww'
  depends_on 'xmlrpc-c'
  depends_on 'boost'
  depends_on 'libair'

  def patches
    # Fix plplot.m4 to use pkg-config and correct library name
    # Fix python.m4 to find system Python executable
    # Fix wvr.m4 to find libair and its header files
    # Remove deprecated includes for glib version >= 2.32 
    # Fix returns in Python wrapper code
    # Build main Obit library as shared dylib
    # Improve installation procedure for Python module
    # Remove unused AIPS objects that introduce undefined symbols
    DATA
  end

  def install
    ENV.deparallelize
    ENV.fortran
    system 'aclocal -I m4; autoconf'
    system './configure'
    system 'make'
    # Since Obit does not do its own 'make install', we have to do it ourselves
    system 'rm -f bin/.cvsignore include/.cvsignore'
    prefix.install 'bin'
    prefix.install 'include'
    lib.install 'lib/libObit.dylib'
    system "mkdir", "-p", "#{lib}/#{which_python}/site-packages"
    system "cp", "-R", "python/build/site-packages", "#{lib}/#{which_python}/"
    system "mkdir", "-p", "#{share}/#{name}"
    system "cp", "-R", "share/data", "share/scripts", "#{share}/#{name}"
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
diff --git a/include/ObitThread.h b/include/ObitThread.h
index 2be8bf2..68ca14a 100644
--- a/include/ObitThread.h
+++ b/include/ObitThread.h
@@ -29,7 +29,6 @@
 #include "ObitErr.h"
 #include "ObitInfoList.h"
 #include <glib.h>
-#include <glib/gthread.h>
 
 /**
  * \file ObitThread.h
diff --git a/m4/plplot.m4 b/m4/plplot.m4
index 9dbca3f..12d8a67 100644
--- a/m4/plplot.m4
+++ b/m4/plplot.m4
@@ -15,10 +15,13 @@ ac_plplot_saved_CPPFLAGS="$CPPFLAGS"
 ac_plplot_saved_CFLAGS="$CFLAGS"
 ac_plplot_saved_LDFLAGS="$LDFLAGS"
 ac_plplot_saved_LIBS="$LIBS"
-if ! test PLPLOT_CFLAGS; then
-    PLPLOT_CFLAGS="`plplot-config --cflags`"
+if test "x$PLPLOT_CFLAGS" = x; then
+    PLPLOT_CFLAGS="`pkg-config plplotd --cflags`"
 fi
-PLPLOT_LIBS="`plplot-config --libs`"
+if test "x$PLPLOT_CPPFLAGS" = x; then
+    PLPLOT_CPPFLAGS="`pkg-config plplotd-c++ --cflags`"
+fi
+PLPLOT_LIBS="`pkg-config plplotd --libs`"
 CPPFLAGS="$CPPFLAGS $PLPLOT_CPPFLAGS"
 CFLAGS="$CFLAGS $PLPLOT_CFLAGS"
 LDFLAGS="$LDFLAGS $PLPLOT_LDFLAGS"
@@ -31,7 +34,7 @@ ac_have_plploth=no
 	[#include "plplot.h"])
 	rm /tmp/dummy1_plplot.h
  	if test $ac_have_plploth = yes; then
-		AC_CHECK_LIB(plplot, c_plinit, [ac_have_plplot=yes], [ac_have_plplot=no])
+		AC_CHECK_LIB(plplotd, c_plinit, [ac_have_plplot=yes], [ac_have_plplot=no])
 	fi
 # List of places to try
 testdirs="$HOME/opt/plplot $OBITINSTALL/other"
@@ -61,7 +64,7 @@ for dir in $testdirs; do
 		fi
 	fi
 done[]
-PLPLOT_LIBS="-lplplot $PLPLOT_LIBS"
+PLPLOT_LIBS="-lplplotd $PLPLOT_LIBS"
 if test $ac_have_plploth = no; then
 	AC_MSG_WARN([cannot find PLPLOT headers])
 	ac_have_plplot=no
@@ -78,7 +81,7 @@ if test $ac_have_plplot = yes; then
 fi
 CPPFLAGS="$ac_plplot_saved_CPPFLAGS"
 CFLAGS="$ac_plplot_saved_CFLAGS"
-LDFLAGS="$LDFLAGS $PLPLOT_LDFLAGS"
+LDFLAGS="$ac_plplot_saved_LDFLAGS"
 LIBS="$ac_plplot_saved_LIBS"
 	 AC_SUBST(PLPLOT_CPPFLAGS)
 	 AC_SUBST(PLPLOT_CFLAGS)
diff --git a/m4/python.m4 b/m4/python.m4
index e729417..728ee71 100644
--- a/m4/python.m4
+++ b/m4/python.m4
@@ -26,7 +26,7 @@ AC_DEFUN([AC_PATH_PYTHON2_5], [
 # Includes
 if test "x$PYTHON_CPPFLAGS" = x; then
     if test "x$PYTHON" = x; then
-        PYTHON=`pwd`/../../bin/python
+        AC_PATH_PROG(PYTHON, python,, `pwd`/../../bin$PATH_SEPARATOR$PATH)
     fi
 cat <<_ACEOF >conftest.py
 import distutils.sysconfig
@@ -40,7 +40,7 @@ fi
 # Python libs
 if test "x$PYTHON_LD_FLAGS" = x; then
     if test "x$PYTHON" = x; then
-        PYTHON=`pwd`/../../bin/python
+        AC_PATH_PROG(PYTHON, python,, `pwd`/../../bin$PATH_SEPARATOR$PATH)
     fi
 cat <<_ACEOF >conftest.py
 import distutils.sysconfig
diff --git a/m4/wvr.m4 b/m4/wvr.m4
index 57a2832..326e60e 100644
--- a/m4/wvr.m4
+++ b/m4/wvr.m4
@@ -23,21 +23,22 @@ AC_DEFUN([AC_PATH_WVR], [
     fi
   done[]])
 
-echo "WVR CFLAGs $WVR_CFLAGS LDFLAGs $WVR_LDFLAGS"
 ac_wvr_saved_CFLAGS="$CFLAGS"
 ac_wvr_saved_LDFLAGS="$LDFLAGS"
 ac_wvr_saved_LIBS="$LIBS"
 CFLAGS="$CFLAGS $WVR_CFLAGS"
 LDFLAGS="$LDFLAGS $WVR_LDFLAGS"
-if ! test WVR_CFLAGS; then
-    WVR_CFLAGS="`--cflags`"
+if test "x$WVR_CFLAGS" = x; then
+    WVR_CFLAGS="`pkg-config libair --cflags`"
 fi
-# not there WVR_LIBS="`wvr-config --libs`"
+WVR_LIBS="`pkg-config libair --libs`"
+echo "WVR CFLAGs: $WVR_CFLAGS LDFLAGs: $WVR_LDFLAGS"
+
 ac_have_wvr=no
 ac_have_wvrh=no
   	touch /tmp/dummy1_wvr.h
         AC_CHECK_HEADERS([/tmp/dummy1_wvr.h], [ac_have_wvrh=yes], [ac_have_wvrh=no],
-			[#include <almawvr/almaabs_c.h>])
+			[#include <almaabs_c.h>])
 	rm /tmp/dummy1_wvr.h
  	if test $ac_have_wvrh = yes; then
 	        AC_SEARCH_LIBS(almaabs_ret, [almawvr], [ac_have_wvr=yes], [ac_have_wvr=no], 
@@ -67,14 +68,14 @@ for dir in $testdirs; do
 		fi
 	fi
 	if test $ac_have_wvr = no; then
-		if  test -f $dir/include/almawvr/almaabs_c.h; then
+		if  test -f $dir/include/almaabs_c.h; then
 			WVR_CFLAGS="-I$dir/include"
 			CPPFLAGS="$ac_wvr_saved_CPPFLAGS $WVR_CFLAGS"
 			WVR_LDFLAGS="-L$dir/lib"
 			LDFLAGS="$ac_wvr_saved_LDFLAGS $WVR_LDFLAGS"
   			touch /tmp/dummy3_wvr.h
 	        	AC_CHECK_HEADERS(/tmp/dummy3_wvr.h, [ac_have_wvrh=yes], [ac_have_wvrh=no],
-				[#include "almawvr/almaabs_c.h"])
+				[#include "almaabs_c.h"])
 			rm /tmp/dummy3_wvr.h
 			if test $ac_have_wvrh = yes; then
 				# Force check
diff --git a/src/ObitSDMData.c b/src/ObitSDMData.c
index 88c3b65..df3cb64 100644
--- a/src/ObitSDMData.c
+++ b/src/ObitSDMData.c
@@ -65,7 +65,6 @@ X    Weather.xml
 #include "ObitSDMData.h"
 #include "ObitEVLASysPower.h"
 #include "ObitFile.h"
-#include "glib/gqsort.h"
 
 /*----------------Obit: Merx mollis mortibus nuper ------------------*/
 /**
diff --git a/src/ObitTableUtil.c b/src/ObitTableUtil.c
index 12ff756..e542569 100644
--- a/src/ObitTableUtil.c
+++ b/src/ObitTableUtil.c
@@ -28,7 +28,6 @@
 
 #include <math.h>
 #include <string.h>
-#include "glib/gqsort.h"
 #include "ObitTableUtil.h"
 #include "ObitImage.h"
 #include "ObitInfoElem.h"
diff --git a/tasks/WVRCal.c b/tasks/WVRCal.c
index 582f1e9..bcbf64f 100644
--- a/tasks/WVRCal.c
+++ b/tasks/WVRCal.c
@@ -45,7 +45,7 @@
 #include "ObitThread.h"
 /* libAir stuff */
 #ifdef HAVE_WVR  /* Only if libAir available */
-#include "almawvr/almaabs_c.h"
+#include "almaabs_c.h"
 #endif /* HAVE_WVR */
   /* Speed of light */
 #ifndef VELIGHT
diff --git a/src/ObitTableCCUtil.c b/src/ObitTableCCUtil.c
index 72e34f2..695f264 100644
--- a/src/ObitTableCCUtil.c
+++ b/src/ObitTableCCUtil.c
@@ -26,7 +26,6 @@
 /*;                         Charlottesville, VA 22903-2475 USA        */
 /*--------------------------------------------------------------------*/
 
-#include "glib/gqsort.h"
 #include "ObitTableCCUtil.h"
 #include "ObitMem.h"
 #include "ObitBeamShape.h"
diff --git a/src/ObitUVSortBuffer.c b/src/ObitUVSortBuffer.c
index 584da07..dc0db38 100644
--- a/src/ObitUVSortBuffer.c
+++ b/src/ObitUVSortBuffer.c
@@ -29,7 +29,6 @@
 #include "ObitUVSortBuffer.h"
 #include <math.h>
 #include <string.h>
-#include "glib/gqsort.h"
 
 /*----------------Obit: Merx mollis mortibus nuper ------------------*/
 /**
diff --git a/python/Obit_wrap.c b/python/Obit_wrap.c
index 519bbec..68c8607 100644
--- a/python/Obit_wrap.c
+++ b/python/Obit_wrap.c
@@ -7827,7 +7827,7 @@ extern ObitTableDesc* TableDescDef(PyObject *inDict) {
   repeat = PyDict_GetItemString(inDict, "repeat");
   if (!repeat) {
     PyErr_SetString(PyExc_TypeError,"repeat Array not found");
-    return;
+    return out;
   }
   if (PyList_Size(repeat)!=nfield) {
     PyErr_SetString(PyExc_TypeError,"repeat Array wrong dimension");
@@ -38607,7 +38607,7 @@ static PyObject *_wrap_SpectrumFitImArr(PyObject *self, PyObject *args) {
          }
          if (!ObitImageIsA((ObitImage*)_arg2[i])) {  // check */
            PyErr_SetString(PyExc_TypeError,"Type error. Expected ObitImage Object.");
-           return;
+           return NULL;
          }
       } else {
          PyErr_SetString(PyExc_TypeError,"list must contain Strings (ObitImage pointers)");
diff --git a/lib/Makefile b/lib/Makefile
index 40d2e7d..f8e4248 100644
--- a/lib/Makefile
+++ b/lib/Makefile
@@ -34,18 +34,22 @@
 #
 #------------------------------------------------------------------------
 # targets to build
-TARGETS =  libObit.a
+TARGETS =  libObit.a libObit.dylib
 
 # list of object modules
 OBJECTS := $(wildcard *.o)
 
 all:  $(TARGETS)
 
-#  build Obit library
+#  build Obit static library
 libObit.a: ${OBJECTS}
 	ar rv libObit.a ${OBJECTS}
 	${RANLIB} libObit.a
 
+# build Obit shared library
+libObit.dylib: $(OBJECTS)
+	$(CC) -dynamiclib -flat_namespace -undefined dynamic_lookup -o $@ $^
+
 clean:
 	rm -f $(TARGETS)
 
diff --git a/tasks/Makefile.in b/tasks/Makefile.in
index 798645f..be4db7d 100644
--- a/tasks/Makefile.in
+++ b/tasks/Makefile.in
@@ -63,10 +63,16 @@ ALL_LDFLAGS = $(LDFLAGS) @CFITSIO_LDFLAGS@ @FFTW_LDFLAGS@  @FFTW3_LDFLAGS@  \
 	 @GSL_LDFLAGS@ @PLPLOT_LDFLAGS@ @PGPLOT_LDFLAGS@ @WVR_LDFLAGS@ \
 	$(CLIENT_LDFLAGS) $(SERVER_LDFLAGS)
 
-LIBS = ../lib/libObit.a @CFITSIO_LIBS@ @FFTW_LIBS@ @FFTW3_LIBS@ @GLIB_LIBS@ \
-	@GSL_LIBS@ @PLPLOT_LIBS@ @PGPLOT_LIBS@ $(CLIENT_LIBS) $(SERVER_LIBS) \
-	@LIBS@ @FLIBS@ @GTHREAD_LIBS@ @WVR_LIBS@
+# Static library option
+# OBIT_LIB_TARGET = ../lib/libObit.a
+# OBIT_LIB = ../lib/libObit.a
+# Shared library option
+OBIT_LIB_TARGET = ../lib/libObit.dylib
+OBIT_LIB = -L../lib -lObit
 
+LIBS = $(OBIT_LIB) @CFITSIO_LIBS@ @FFTW_LIBS@ @FFTW3_LIBS@ @GLIB_LIBS@ \
+        @GSL_LIBS@ @PLPLOT_LIBS@ @PGPLOT_LIBS@ $(CLIENT_LIBS) $(SERVER_LIBS) \
+        @LIBS@ @FLIBS@ @GTHREAD_LIBS@ @WVR_LIBS@
 
 # get list of all c source files (*.c) files
 AllC    := $(wildcard *.c)
@@ -76,17 +82,18 @@ TARGETS := $(addprefix $(BINDIR),$(EXECU))
 all: $(TARGETS)
 
 # generic C compile/link
-$(TARGETS): $(BINDIR)% : %.c ../lib/libObit.a  
+$(TARGETS): $(BINDIR)% : %.c $(OBIT_LIB_TARGET)
 	echo "compile $*.c"
 	$(CC) $(ALL_CPPFLAGS) $(ALL_CFLAGS) $(ALL_LDFLAGS) $*.c -o $* $(LIBS)
 	mv $* $(BINDIR)
 
 # For specific executables
-$(EXECU): % : %.c ../lib/libObit.a  
+$(EXECU): % : %.c $(OBIT_LIB_TARGET)
 	$(CC) $(ALL_CPPFLAGS) $(ALL_CFLAGS) $(ALL_LDFLAGS) $< -o $* $(LIBS)
 	mv $* $(BINDIR)
 
 clean:
 	rm -f $(TARGETS)
 	rm -f *.o
+	rm -rf *.dSYM
 
diff --git a/python/Makefile.in b/python/Makefile.in
index 5cf25a4..5dac1d6 100644
--- a/python/Makefile.in
+++ b/python/Makefile.in
@@ -54,7 +54,12 @@ ALL_CFLAGS = $(CFLAGS) @GLIB_CFLAGS@ @GSL_CFLAGS@ @PLPLOT_CFLAGS@ \
 ALL_LDFLAGS = $(LDFLAGS) @CFITSIO_LDFLAGS@ @FFTW_LDFLAGS@  @FFTW3_LDFLAGS@  @GSL_LDFLAGS@ \
 	@PLPLOT_LDFLAGS@ @PGPLOT_LDFLAGS@ @PYTHON_LDFLAGS@ 
 
-LIBS = ../lib/libObit.a @CFITSIO_LIBS@ @FFTW_LIBS@ @FFTW3_LIBS@ @GLIB_LIBS@ \
+# Static library option
+# OBIT_LIB = ../lib/libObit.a
+# Shared library option
+OBIT_LIB = -L../lib -lObit
+
+LIBS = $(OBIT_LIB) @CFITSIO_LIBS@ @FFTW_LIBS@ @FFTW3_LIBS@ @GLIB_LIBS@ \
 	@GSL_LIBS@ @PLPLOT_LIBS@ @PGPLOT_LIBS@ @LIBS@ @FLIBS@ @GTHREAD_LIBS@
 
 CLIENT_CPPFLAGS = $(ALL_CPPFLAGS) @XMLRPC_CLIENT_CPPFLAGS@ 
@@ -71,12 +76,13 @@ SERVER_LIBS =  @XMLRPC_SERVER_LIBS@
 SWIG = @SWIG@
 
 # Libraries in case they've changed
-MYLIBS := $(wildcard ../lib/lib*.a)
+# MYLIBS := $(wildcard ../lib/lib*.a)
+MYLIBS := $(wildcard ../lib/lib*.dylib)
 
 # Do everything in one big module
-TARGETS := Obit.so 
+TARGETS := Obit.so
 
-all: $(TARGETS)
+all: install
 
 # Build shared library for python interface
 $(TARGETS): setupdata.py $(MYLIBS)
@@ -84,6 +90,10 @@ $(TARGETS): setupdata.py $(MYLIBS)
 	python makesetup.py
 	python setup.py build install --install-lib=.
 
+install: $(TARGETS)
+	mkdir -p build/site-packages
+	cp *.py $(TARGETS) build/site-packages
+
 # Build python/Obit interface
 interface: Obit_wrap.c
 	echo "rebuild Obit/python interface"
diff --git a/Makefile.in b/Makefile.in
index b76a1a4..d2667ac 100644
--- a/Makefile.in
+++ b/Makefile.in
@@ -87,7 +87,7 @@ srcupdate:
 
 # update library directory
 libupdate: 
-	cd lib; $(MAKE) RANLIB="$(RANLIB)"
+	cd lib; $(MAKE) RANLIB="$(RANLIB)" CC="$(CC)"
 
 # update test software directory
 testupdate: 
diff --git a/src/Makefile.in b/src/Makefile.in
index 547ddc1..e8c56f1 100644
--- a/src/Makefile.in
+++ b/src/Makefile.in
@@ -53,7 +53,7 @@ ALL_CFLAGS = $(CFLAGS) @GSL_CFLAGS@ @GLIB_CFLAGS@ @PLPLOT_CFLAGS@ \
 	mv $@.o $(LIBDIR)
 
 # get list of all c source files (*.c) files
-AllC := $(wildcard *.c)
+AllC := $(filter-out ObitAIPSFortran.c, $(filter-out ObitAIPSObject.c, $(wildcard *.c)))
 OBJECTS := $(patsubst %.c,%.o, $(AllC))
 
 CTARGETS := $(addprefix $(LIBDIR),$(OBJECTS))
 
