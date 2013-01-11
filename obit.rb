require 'formula'

class ObitDownloadStrategy < SubversionDownloadStrategy
  def stage
    # Bake SVN revision into ObitVersion.c before staging/exporting the Obit tarball without commit history
    quiet_system 'python', cached_location+'Obit/share/scripts/getVersion.py', cached_location+'Obit'
    ohai 'Obit version is ' + File.open(cached_location+'Obit/src/ObitVersion.c').read[/"(\d+M*)"/][$1]
    super
  end
end

class Obit < Formula
  homepage 'http://www.cv.nrao.edu/~bcotton/Obit.html'
  head 'https://svn.cv.nrao.edu/svn/ObitInstall/ObitSystem', :using => ObitDownloadStrategy

  # We need to find the MacTeX executables in order to build the Obit
  # user manuals and they are not in the Homebrew restricted path.
  # Also, since Obit is still quite experimental we want debug symbols
  # included, which are aggressively stripped out in superenv.
  env :std

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'pkg-config' => :build

  depends_on 'pgplot'
  depends_on 'cfitsio'
  depends_on 'glib'
  depends_on 'fftw'
  depends_on 'gsl'
  depends_on 'lesstif'
  depends_on 'xmlrpc-c'
  depends_on 'boost'
  depends_on 'libair'

  def patches
    # Fix python.m4 to find system Python executable
    # Fix wvr.m4 to find libair and its header files
    # Remove deprecated includes for glib version >= 2.32 
    # Fix returns in Python wrapper code
    # Build main Obit library as shared dylib
    # Improve installation procedure for Python module
    # Remove unused AIPS objects that introduce undefined symbols
    # Make creation of doc directory idempotent
    # Fix detection of XMLRPC libs in ObitView obit.m4 test
    # Fix bus error that manifested in BPass by adding index check
    # Don't update version in install as it is done as part of staging now
    # Allow test scripts to run in any directory containing data
    DATA
  end

  def install
    ENV.deparallelize
    ENV.fortran

    ohai 'Building and installing main Obit package'
    ohai '-----------------------------------------'
    cd 'Obit'
    safe_system 'aclocal -I m4; autoconf'
    system './configure', "--prefix=#{prefix}"
    system 'make'
    safe_system 'dsymutil lib/libObit.dylib'
    # Since Obit does not do its own 'make install', we have to do it ourselves
    ohai 'make install'
    rm_f ['bin/.cvsignore', 'include/.cvsignore']
    prefix.install 'bin'
    prefix.install 'include'
    lib.install 'lib/libObit.dylib', 'lib/libObit.dylib.dSYM'
    mkdir_p "#{lib}/#{which_python}/site-packages"
    cp_r 'python/build/site-packages', "#{lib}/#{which_python}/"
    mkdir_p "#{share}/obit"
    cp_r ['share/data', 'share/scripts', 'TDF'], "#{share}/obit"
    mkdir_p ["#{share}/obit/data/test", "#{share}/obit/scripts/test"]
    cp 'testData/AGNVLA.fits.gz', "#{share}/obit/data/test"
    cp 'testScripts/testContourPlot.py', "#{share}/obit/scripts/test"

    ohai 'Building and installing ObitTalk package'
    ohai '----------------------------------------'
    cd '../ObitTalk'
    inreplace 'bin/ObitTalk.in', '@datadir@/python', "#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages"
    inreplace 'bin/ObitTalkServer.in', '@datadir@/python', "#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages"
    inreplace 'python/Makefile.in', 'share/obittalk/python', "lib/#{which_python}/site-packages"
    inreplace 'python/Proxy/Makefile.in', '$(pkgdatadir)/python', "$(prefix)/lib/#{which_python}/site-packages"
    inreplace 'python/Wizardry/Makefile.in', '$(pkgdatadir)/python', "$(prefix)/lib/#{which_python}/site-packages"
    inreplace 'python/Proxy/ObitTask.py', '/usr/lib/obit/tdf', "#{share}/obit/TDF"
    inreplace 'python/Proxy/ObitTask.py', '/usr/lib/obit/bin', "#{bin}"
    inreplace 'doc/Makefile.in', '../../doc', "#{share}/doc/obit"
    system './configure', "PYTHONPATH=#{lib}/#{which_python}/site-packages:$PYTHONPATH", "DYLD_LIBRARY_PATH=#{lib}",
           "--prefix=#{prefix}"
    system 'make'
    system 'make', 'install', "prefix=#{prefix}"

    ohai 'Building and installing ObitView package'
    ohai '----------------------------------------'
    cd '../ObitView'
    safe_system 'aclocal -I m4; autoconf'
    system './configure', 'LDFLAGS=-L/usr/X11/lib', "--with-obit=#{prefix}", "--prefix=#{prefix}"
    system 'make'
    system 'make', 'install', "prefix=#{prefix}"
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
    mktemp do
      # Test plotting functionality via pgplot / plplot
      cp "#{share}/obit/data/test/AGNVLA.fits.gz", '.'
      safe_system 'python', "#{share}/obit/scripts/test/testContourPlot.py"
      if File.exists?('testCont.ps') then
        ohai 'testContourPlot OK'
      else
        onoe 'testContourPlot FAILED'
      end
    end
  end
end

__END__
diff --git a/Obit/include/ObitThread.h b/Obit/include/ObitThread.h
index 2be8bf2..68ca14a 100644
--- a/Obit/include/ObitThread.h
+++ b/Obit/include/ObitThread.h
@@ -29,7 +29,6 @@
 #include "ObitErr.h"
 #include "ObitInfoList.h"
 #include <glib.h>
-#include <glib/gthread.h>
 
 /**
  * \file ObitThread.h
diff --git a/Obit/m4/python.m4 b/Obit/m4/python.m4
index e729417..728ee71 100644
--- a/Obit/m4/python.m4
+++ b/Obit/m4/python.m4
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
diff --git a/Obit/m4/wvr.m4 b/Obit/m4/wvr.m4
index 57a2832..326e60e 100644
--- a/Obit/m4/wvr.m4
+++ b/Obit/m4/wvr.m4
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
diff --git a/Obit/src/ObitSDMData.c b/Obit/src/ObitSDMData.c
index 88c3b65..df3cb64 100644
--- a/Obit/src/ObitSDMData.c
+++ b/Obit/src/ObitSDMData.c
@@ -65,7 +65,6 @@ X    Weather.xml
 #include "ObitSDMData.h"
 #include "ObitEVLASysPower.h"
 #include "ObitFile.h"
-#include "glib/gqsort.h"
 
 /*----------------Obit: Merx mollis mortibus nuper ------------------*/
 /**
diff --git a/Obit/src/ObitTableUtil.c b/Obit/src/ObitTableUtil.c
index 12ff756..e542569 100644
--- a/Obit/src/ObitTableUtil.c
+++ b/Obit/src/ObitTableUtil.c
@@ -28,7 +28,6 @@
 
 #include <math.h>
 #include <string.h>
-#include "glib/gqsort.h"
 #include "ObitTableUtil.h"
 #include "ObitImage.h"
 #include "ObitInfoElem.h"
diff --git a/Obit/tasks/WVRCal.c b/Obit/tasks/WVRCal.c
index 582f1e9..bcbf64f 100644
--- a/Obit/tasks/WVRCal.c
+++ b/Obit/tasks/WVRCal.c
@@ -45,7 +45,7 @@
 #include "ObitThread.h"
 /* libAir stuff */
 #ifdef HAVE_WVR  /* Only if libAir available */
-#include "almawvr/almaabs_c.h"
+#include "almaabs_c.h"
 #endif /* HAVE_WVR */
   /* Speed of light */
 #ifndef VELIGHT
diff --git a/Obit/src/ObitTableCCUtil.c b/Obit/src/ObitTableCCUtil.c
index 72e34f2..695f264 100644
--- a/Obit/src/ObitTableCCUtil.c
+++ b/Obit/src/ObitTableCCUtil.c
@@ -26,7 +26,6 @@
 /*;                         Charlottesville, VA 22903-2475 USA        */
 /*--------------------------------------------------------------------*/
 
-#include "glib/gqsort.h"
 #include "ObitTableCCUtil.h"
 #include "ObitMem.h"
 #include "ObitBeamShape.h"
diff --git a/Obit/src/ObitUVSortBuffer.c b/Obit/src/ObitUVSortBuffer.c
index 584da07..dc0db38 100644
--- a/Obit/src/ObitUVSortBuffer.c
+++ b/Obit/src/ObitUVSortBuffer.c
@@ -29,7 +29,6 @@
 #include "ObitUVSortBuffer.h"
 #include <math.h>
 #include <string.h>
-#include "glib/gqsort.h"
 
 /*----------------Obit: Merx mollis mortibus nuper ------------------*/
 /**
diff --git a/Obit/python/Obit_wrap.c b/Obit/python/Obit_wrap.c
index 519bbec..68c8607 100644
--- a/Obit/python/Obit_wrap.c
+++ b/Obit/python/Obit_wrap.c
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
diff --git a/Obit/lib/Makefile b/Obit/lib/Makefile
index 40d2e7d..f8e4248 100644
--- a/Obit/lib/Makefile
+++ b/Obit/lib/Makefile
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
 
diff --git a/Obit/tasks/Makefile.in b/Obit/tasks/Makefile.in
index 798645f..be4db7d 100644
--- a/Obit/tasks/Makefile.in
+++ b/Obit/tasks/Makefile.in
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
 
diff --git a/Obit/python/Makefile.in b/Obit/python/Makefile.in
index 5cf25a4..5dac1d6 100644
--- a/Obit/python/Makefile.in
+++ b/Obit/python/Makefile.in
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
diff --git a/Obit/Makefile.in b/Obit/Makefile.in
index b76a1a4..d2667ac 100644
--- a/Obit/Makefile.in
+++ b/Obit/Makefile.in
@@ -87,7 +87,7 @@ srcupdate:
 
 # update library directory
 libupdate: 
-	cd lib; $(MAKE) RANLIB="$(RANLIB)"
+	cd lib; $(MAKE) RANLIB="$(RANLIB)" CC="$(CC)"
 
 # update test software directory
 testupdate: 
diff --git a/Obit/src/Makefile.in b/Obit/src/Makefile.in
index 547ddc1..e8c56f1 100644
--- a/Obit/src/Makefile.in
+++ b/Obit/src/Makefile.in
@@ -53,7 +53,7 @@ ALL_CFLAGS = $(CFLAGS) @GSL_CFLAGS@ @GLIB_CFLAGS@ @PLPLOT_CFLAGS@ \
 	mv $@.o $(LIBDIR)
 
 # get list of all c source files (*.c) files
-AllC := $(wildcard *.c)
+AllC := $(filter-out ObitAIPSFortran.c, $(filter-out ObitAIPSObject.c, $(wildcard *.c)))
 OBJECTS := $(patsubst %.c,%.o, $(AllC))
 
 CTARGETS := $(addprefix $(LIBDIR),$(OBJECTS))
diff --git a/ObitTalk/python/Makefile.in b/ObitTalk/python/Makefile.in
index d2a2b26..e479a41 100644
--- a/ObitTalk/python/Makefile.in
+++ b/ObitTalk/python/Makefile.in
@@ -76,8 +76,8 @@ PROXYTAR:= $(DESTDIR)$(PYTHONDIR)/Proxy/AIPSData.py \
 WIZTAR:= $(DESTDIR)$(PYTHONDIR)/Wizardry/AIPSData.py \
 	$(DESTDIR)$(PYTHONDIR)/Wizardry/__init__.py
 
-# make all = directories
-all:  $(DESTDIR)$(PREFIX)/share $(DESTDIR)$(PREFIX)/share/obittalk 
+all:
+	echo "Nothing to make."
 
 install: $(PYTHONTAR) $(PROXYTAR) $(WIZTAR)
 
diff --git a/ObitTalk/doc/Makefile.in b/ObitTalk/doc/Makefile.in
index 7426d1d..79501bc 100644
--- a/ObitTalk/doc/Makefile.in
+++ b/ObitTalk/doc/Makefile.in
@@ -44,7 +44,7 @@ install: $(DOCDIR)
 	cp *.pdf $(DOCDIR)
 
 $(DOCDIR):
-	mkdir $(DOCDIR)
+	mkdir -p $(DOCDIR)
 
 
 # clean up derived files
diff --git a/ObitView/m4/obit.m4 b/ObitView/m4/obit.m4
index 9e141d9..c2ac834 100644
--- a/ObitView/m4/obit.m4
+++ b/ObitView/m4/obit.m4
@@ -1,7 +1,7 @@
 # Find Obit libraries
 AC_DEFUN([AC_PATH_OBIT], [
-XMLRPC_LIBS="$XMLRPC_LIBS $GSL_LIBS $FFTW3_LIBS -lxmlrpc_abyss -lxmlrpc_client -lxmlrpc_server_abyss -lxmlrpc_server_cgi -lxmlrpc_server -lxmlrpc -lxmlrpc_util -lxmlrpc_xmlparse -lxmlrpc_xmltok"
-LIBS="$LIBS $XMLRPC_LIBS -lm -lcfitsio"
+XMLRPC_LIBS="$XMLRPC_LIBS `xmlrpc-c-config client --libs` `xmlrpc-c-config abyss-server --libs`  "
+LIBS="$LIBS $XMLRPC_LIBS $GSL_LIBS $FFTW3_LIBS -lm -lcfitsio"
 
 # Default root of Obit directory is $OBIT
 	OBIT_DIR="$OBIT"
diff --git a/Obit/src/ObitTableCLUtil.c b/Obit/src/ObitTableCLUtil.c
index 5ddb846..d73a88e 100644
--- a/Obit/src/ObitTableCLUtil.c
+++ b/Obit/src/ObitTableCLUtil.c
@@ -452,14 +452,14 @@ ObitTableCL* ObitTableCLGetDummy (ObitUV *inUV, ObitUV *outUV, olong ver,
 	      /* Values for start of next scan */
 	      row->Time   = rec[inUV->myDesc->iloct]; 
 	      row->TimeI  = 0.0;
-	      row->SourID = (oint)(rec[inUV->myDesc->ilocsu]+0.5);
+	      if (inUV->myDesc->ilocsu>=0) row->SourID = (oint)(rec[inUV->myDesc->ilocsu]+0.5);
 	      row->SubA   = SubA;
 	    } /* end write beginning of scan value */
 	  } else {  /* in middle of scan - use average time */
 	    /* Set descriptive info on Row */
 	    row->Time  = sumTime/nTime;  /* time */
 	    row->TimeI = MAX (0.0, (2.0 * (row->Time - t0)));
-	    row->SourID = (oint)(rec[inUV->myDesc->ilocsu]+0.5);
+	    if (inUV->myDesc->ilocsu>=0) row->SourID = (oint)(rec[inUV->myDesc->ilocsu]+0.5);
 	    row->SubA   = SubA;
 	  }
       
diff --git a/Obit/Makefile.in b/Obit/Makefile.in
index d2667ac..bf2c392 100644
--- a/Obit/Makefile.in
+++ b/Obit/Makefile.in
@@ -56,7 +56,7 @@ DISTRIB = @PACKAGE_TARNAME@@PACKAGE_VERSION@
 DIRN = @PACKAGE_NAME@
 
 #------------------------------------------------------------------------
-TARGETS = versionupdate cfitsioupdate xmlrpcupdate srcupdate libupdate \
+TARGETS = cfitsioupdate xmlrpcupdate srcupdate libupdate \
 	pythonupdate taskupdate
 
 all:  $(TARGETS)
diff --git a/Obit/testScripts/testContourPlot.py b/Obit/testScripts/testContourPlot.py
index f1305e2..434b431 100644
--- a/Obit/testScripts/testContourPlot.py
+++ b/Obit/testScripts/testContourPlot.py
@@ -1,8 +1,8 @@
 # test Contour plot
-import Obit, OTObit, Image, ImageUtil, OSystem, OErr, OPlot, math
+import Obit, OTObit, Image, ImageUtil, OSystem, OErr, OPlot, math, os
 # Init Obit
 err=OErr.OErr()
-ObitSys=OSystem.OSystem ("Plot", 1, 100, 0, ["None"], 1, ["../testIt/"], 1, 0, err)
+ObitSys=OSystem.OSystem ("Plot", 1, 100, 0, ["None"], 1, [os.getcwd()], 1, 0, err)
 OErr.printErrMsg(err, "Error with Obit startup")
 
 # Contour plot
