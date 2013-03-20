require 'formula'

class ObitDownloadStrategy < SubversionDownloadStrategy
  def stage
    # Bake SVN revision into ObitVersion.c before staging/exporting the Obit tarball without commit history
    quiet_system 'python', cached_location+'Obit/share/scripts/getVersion.py', cached_location+'Obit'
    ohai 'Obit version is ' + File.open(cached_location+'Obit/src/ObitVersion.c') {|f| f.read[/"(\d+M*)"/][$1]}
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
    # Add missing build dependencies to enable parallel builds
    DATA
  end

  def install
    ENV.fortran

    ohai 'Building and installing main Obit package'
    ohai '-----------------------------------------'
    cd 'Obit'
    safe_system 'aclocal -I m4; autoconf'
    system './configure', "--prefix=#{prefix}"
    system 'make'
    # Assemble debug symbol (*.dSYM) files
    safe_system 'dsymutil', 'lib/libObit.dylib', 'python/build/site-packages/Obit.so'
    # Since Obit does not do its own 'make install', we have to do it ourselves
    ohai 'make install'
    rm_f ['bin/.cvsignore', 'include/.cvsignore']
    prefix.install 'bin'
    prefix.install 'include'
    lib.install Dir['lib/libObit.dylib*']
    mkdir_p "#{lib}/#{which_python}/site-packages"
    cp_r 'python/build/site-packages', "#{lib}/#{which_python}/"
    mkdir_p "#{share}/obit"
    cp_r ['share/data', 'share/scripts', 'TDF'], "#{share}/obit"
    mv 'testData', "#{share}/obit/data/test"
    mv 'testScripts', "#{share}/obit/scripts/test"

    ohai 'Building and installing ObitTalk package'
    ohai '----------------------------------------'
    cd '../ObitTalk'
    begin
      # Check for the presence of LaTeX and friends
      quiet_system 'latex --version'
      quiet_system 'bibtex --version'
      quiet_system 'dvips --version'
      quiet_system 'which dvipdf'
    rescue ErrorDuringExecution
      # Remove the documentation build (brittle but preferable to getting aclocal and automake involved)
      inreplace 'Makefile.in', ' doc', ''
      opoo 'No TeX installation found - documentation will not be built (please install MacTeX first if you want docs)'
    end
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
      cp_r "#{share}/obit/data/test", 'data'
      safe_system 'gunzip data/*.gz'
      tests = ['testObit', 'testContourPlot', 'testFeather', 'testHGeom',
               'testUVImage', 'testUVSub', 'testCleanVis']
      tests.each do |name|
        safe_system 'python', "#{share}/obit/scripts/test/#{name}.py", 'data'
        ohai "#{name} OK"
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
diff --git a/Obit/Makefile.in b/Obit/Makefile.in
index bf2c392..2b27f6e 100644
--- a/Obit/Makefile.in
+++ b/Obit/Makefile.in
@@ -86,15 +86,15 @@ srcupdate:
 	cd src; $(MAKE)
 
 # update library directory
-libupdate: 
+libupdate: srcupdate
 	cd lib; $(MAKE) RANLIB="$(RANLIB)" CC="$(CC)"
 
 # update test software directory
-testupdate: 
+testupdate: libupdate
 	cd test; $(MAKE)
 
 # update task software directory
-taskupdate: 
+taskupdate: libupdate
 	cd tasks; $(MAKE)
 
 # update work directory
@@ -102,7 +102,7 @@ work:
 	cd src/work; $(MAKE) CC="$(CC)" CFLAGS="$(CFLAGS)" LIB="$(LIB)"
 
 # update python directory
-pythonupdate: 
+pythonupdate: libupdate
 	cd python; $(MAKE)
 
 # update from cvs repository
diff --git a/ObitTalk/python/Makefile.in b/ObitTalk/python/Makefile.in
index e479a41..b5eb152 100644
--- a/ObitTalk/python/Makefile.in
+++ b/ObitTalk/python/Makefile.in
@@ -95,7 +95,7 @@ $(DESTDIR)$(PREFIX)/share: $(DESTDIR)$(PREFIX)
 $(DESTDIR)$(PREFIX)/share/obittalk: $(DESTDIR)$(PREFIX)/share
 	if test ! -d $(DESTDIR)$(PREFIX)/share/obittalk; then mkdir $(DESTDIR)$(PREFIX)/share/obittalk; fi
 
-$(DESTDIR)$(PYTHONDIR):$(DESTDIR)$(PREFIX)/share/obittalk
+$(DESTDIR)$(PYTHONDIR):
 	if test ! -d $(DESTDIR)$(PYTHONDIR); then mkdir $(DESTDIR)$(PYTHONDIR); fi
 
 $(DESTDIR)$(PROXYDIR):$(DESTDIR)$(PYTHONDIR)
@@ -107,49 +107,49 @@ $(DESTDIR)$(WIZDIR):$(DESTDIR)$(PYTHONDIR)
 $(DESTDIR)$(PYTHONDIR)/AIPSData.py: AIPSData.py $(DESTDIR)$(PYTHONDIR) 
 	cp AIPSData.py $@
 
-$(DESTDIR)$(PYTHONDIR)/AIPS.py: AIPS.py
+$(DESTDIR)$(PYTHONDIR)/AIPS.py: AIPS.py $(DESTDIR)$(PYTHONDIR)
 	cp AIPS.py $@
 
-$(DESTDIR)$(PYTHONDIR)/AIPSTask.py: AIPSTask.py
+$(DESTDIR)$(PYTHONDIR)/AIPSTask.py: AIPSTask.py $(DESTDIR)$(PYTHONDIR)
 	cp AIPSTask.py $@
 
-$(DESTDIR)$(PYTHONDIR)/AIPSTV.py: AIPSTV.py
+$(DESTDIR)$(PYTHONDIR)/AIPSTV.py: AIPSTV.py $(DESTDIR)$(PYTHONDIR)
 	cp AIPSTV.py $@
 
-$(DESTDIR)$(PYTHONDIR)/AIPSUtil.py: AIPSUtil.py
+$(DESTDIR)$(PYTHONDIR)/AIPSUtil.py: AIPSUtil.py $(DESTDIR)$(PYTHONDIR)
 	cp AIPSUtil.py $@
 
-$(DESTDIR)$(PYTHONDIR)/FITSData.py: FITSData.py
+$(DESTDIR)$(PYTHONDIR)/FITSData.py: FITSData.py $(DESTDIR)$(PYTHONDIR)
 	cp FITSData.py $@
 
-$(DESTDIR)$(PYTHONDIR)/FITS.py: FITS.py
+$(DESTDIR)$(PYTHONDIR)/FITS.py: FITS.py $(DESTDIR)$(PYTHONDIR)
 	cp FITS.py $@
 
-$(DESTDIR)$(PYTHONDIR)/LocalProxy.py: LocalProxy.py
+$(DESTDIR)$(PYTHONDIR)/LocalProxy.py: LocalProxy.py $(DESTDIR)$(PYTHONDIR)
 	cp LocalProxy.py $@
 
-$(DESTDIR)$(PYTHONDIR)/MinimalMatch.py: MinimalMatch.py
+$(DESTDIR)$(PYTHONDIR)/MinimalMatch.py: MinimalMatch.py $(DESTDIR)$(PYTHONDIR)
 	cp MinimalMatch.py $@
 
-$(DESTDIR)$(PYTHONDIR)/ObitTalk.py: ObitTalk.py
+$(DESTDIR)$(PYTHONDIR)/ObitTalk.py: ObitTalk.py $(DESTDIR)$(PYTHONDIR)
 	cp ObitTalk.py $@
 
-$(DESTDIR)$(PYTHONDIR)/ObitTalkUtil.py: ObitTalkUtil.py
+$(DESTDIR)$(PYTHONDIR)/ObitTalkUtil.py: ObitTalkUtil.py $(DESTDIR)$(PYTHONDIR)
 	cp ObitTalkUtil.py $@
 
-$(DESTDIR)$(PYTHONDIR)/ObitTask.py: ObitTask.py
+$(DESTDIR)$(PYTHONDIR)/ObitTask.py: ObitTask.py $(DESTDIR)$(PYTHONDIR)
 	cp ObitTask.py $@
 
-$(DESTDIR)$(PYTHONDIR)/ObitScript.py: ObitScript.py
+$(DESTDIR)$(PYTHONDIR)/ObitScript.py: ObitScript.py $(DESTDIR)$(PYTHONDIR)
 	cp ObitScript.py $@
 
-$(DESTDIR)$(PYTHONDIR)/otcompleter.py: otcompleter.py
+$(DESTDIR)$(PYTHONDIR)/otcompleter.py: otcompleter.py $(DESTDIR)$(PYTHONDIR)
 	cp otcompleter.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Task.py: Task.py
+$(DESTDIR)$(PYTHONDIR)/Task.py: Task.py $(DESTDIR)$(PYTHONDIR)
 	cp Task.py $@
 
-$(DESTDIR)$(PYTHONDIR)/XMLRPCServer.py: XMLRPCServer.py
+$(DESTDIR)$(PYTHONDIR)/XMLRPCServer.py: XMLRPCServer.py $(DESTDIR)$(PYTHONDIR)
 	cp XMLRPCServer.py $@
 
 
@@ -160,32 +160,32 @@ $(DESTDIR)$(PYTHONDIR)/Proxy/AIPSData.py: Proxy/AIPSData.py $(DESTDIR)$(PROXYDIR
 $(DESTDIR)$(PYTHONDIR)/Proxy/FITSData.py: Proxy/FITSData.py $(DESTDIR)$(PROXYDIR) 
 	cp ./Proxy/FITSData.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/AIPS.py: Proxy/AIPS.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/AIPS.py: Proxy/AIPS.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/AIPS.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/AIPSTask.py: Proxy/AIPSTask.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/AIPSTask.py: Proxy/AIPSTask.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/AIPSTask.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/__init__.py: Proxy/__init__.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/__init__.py: Proxy/__init__.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/__init__.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/ObitTask.py: Proxy/ObitTask.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/ObitTask.py: Proxy/ObitTask.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/ObitTask.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/ObitScriptP.py: Proxy/ObitScriptP.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/ObitScriptP.py: Proxy/ObitScriptP.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/ObitScriptP.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/Popsdat.py: Proxy/Popsdat.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/Popsdat.py: Proxy/Popsdat.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/Popsdat.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Proxy/Task.py: Proxy/Task.py
+$(DESTDIR)$(PYTHONDIR)/Proxy/Task.py: Proxy/Task.py $(DESTDIR)$(PROXYDIR)
 	cp ./Proxy/Task.py $@
 
 # Wizardry
 $(DESTDIR)$(PYTHONDIR)/Wizardry/AIPSData.py: Wizardry/AIPSData.py $(DESTDIR)$(WIZDIR) 
 	cp ./Wizardry/AIPSData.py $@
 
-$(DESTDIR)$(PYTHONDIR)/Wizardry/__init__.py: Wizardry/__init__.py
+$(DESTDIR)$(PYTHONDIR)/Wizardry/__init__.py: Wizardry/__init__.py $(DESTDIR)$(WIZDIR)
 	cp ./Wizardry/__init__.py $@
 
 clean:
diff --git a/ObitView/Makefile.in b/ObitView/Makefile.in
index fbfa6cb..ec98c8a 100644
--- a/ObitView/Makefile.in
+++ b/ObitView/Makefile.in
@@ -88,47 +88,47 @@ CLIENT_LIBS = lib/libObitView.a @MOTIF_LIBS@ @X_LIBS@ @OBIT_LIBS@  @GLIB_LIBS@ \
 all:  $(TARGETS)
 
 # update source/object directory
-srcupdate: 
+srcupdate: src/*.c
 	cd src; $(MAKE)
 
 # update library directory
-libupdate: 
+libupdate: srcupdate
 	cd lib; $(MAKE) RANLIB="$(RANLIB)"
 
 # Link ObitView
-ObitView: src/*.c  srcupdate ObitView.c 
+ObitView: libupdate ObitView.c 
 	$(CC) ObitView.c -o ObitView  $(SERVER_CFLAGS) $(SERVER_CPPFLAGS) \
 	$(SERVER_LDFLAGS) $(SERVER_LIBS) $(CLIENT_LIBS) 
 
 # Link ObitMess
-ObitMess: src/*.c  srcupdate ObitMess.c 
+ObitMess: libupdate ObitMess.c 
 	$(CC) ObitMess.c -o ObitMess  $(SERVER_CFLAGS) $(SERVER_CPPFLAGS) \
 	$(SERVER_LDFLAGS) $(SERVER_LIBS) $(CLIENT_LIBS) 
 
 # Link clientTest
-clientTest:   clientTest.c 
+clientTest: libupdate clientTest.c 
 	$(CC) clientTest.c -o clientTest  -Iinclude $(CLIENT_CFLAGS) \
 	$(CLIENT_CPPFLAGS) $(CLIENT_LDFLAGS) \
 	$(CLIENT_LIBS)
 
 # Link clientFCopy
-clientFCopy:   clientFCopy.c 
+clientFCopy: libupdate clientFCopy.c 
 	$(CC) clientFCopy.c -o clientFCopy  -Iinclude $(CLIENT_CFLAGS) \
 	$(CLIENT_CPPFLAGS) $(CLIENT_LDFLAGS) \
 	$(CLIENT_LIBS)
 
 # test run ObitView
-testObitView: 
+testObitView: ObitView
 	ObitView aaaSomeFile.fits
 
 # test run ObitMess
-testObitMess: 
+testObitMess: ObitMess
 	ObitMess &
 	# Need to wait to start
 	python testObitMess.py
 
 # Copy to where it should go
-install: @exec_prefix@/bin
+install: @exec_prefix@/bin ObitView ObitMess
 	@install_sh@ -s ObitView @exec_prefix@/bin/
 	@install_sh@ -s ObitMess @exec_prefix@/bin/
 
