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
    # Build main Obit library as shared dylib
    # Improve installation procedure for Python module
    # Don't update version in install as it is done as part of staging now
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
#    safe_system 'aclocal -I m4; autoconf'
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
      safe_system 'python', "#{share}/obit/scripts/test/testContourPlot.py", '.'
      if File.exists?('testCont.ps') then
        ohai 'testContourPlot OK'
      else
        onoe 'testContourPlot FAILED'
      end
    end
  end
end

__END__
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
