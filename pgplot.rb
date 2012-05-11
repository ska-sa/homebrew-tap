require 'formula'

class Pgplot < Formula
  url 'ftp://ftp.astro.caltech.edu/pub/pgplot/pgplot5.2.tar.gz'
  homepage 'http://www.astro.caltech.edu/~tjp/pgplot/'
  md5 'e8a6e8d0d5ef9d1709dfb567724525ae'

  def patches
    # Patch 1: Small fix needed to use the 64-bit PNG output driver.
    # The remainder are needed to convince the awful PGPLOT build system to
    # make use of gfortran, and to *not* attempt to build PGPLOT in another
    # directory. Shared library creation is broken, and so is disabled here.
    DATA end

  def install
    ENV.fortran
    ENV.j1
    inreplace "drivers.list", "! XWDRIV", "  XWDRIV"
    inreplace "drivers.list", "! PSDRIV", "  PSDRIV"
    system "./makemake . linux g77_gcc" 
    system "make"
    system "make cpg"
    prefix.install ['grfont.dat','rgb.txt','grexec.f','grpckg1.inc','pgplot.inc']
    prefix.install ['pgxwin_server']
    lib.install ['libpgplot.a','libcpgplot.a']
    bin.install ['pgdemo1','pgdemo2','pgdemo3','pgdemo4','pgdemo5']
    bin.install ['pgdemo6','pgdemo7','pgdemo8','pgdemo9','pgdemo10']
    bin.install ['pgdemo11','pgdemo12','pgdemo13','pgdemo14','pgdemo15']
    bin.install ['pgdemo16','pgdemo17','cpgdemo']
  end
end

__END__
diff --git a/drivers/gidriv.f b/drivers/gidriv.f
index 20a2aab..ffd1070 100644
--- a/drivers/gidriv.f
+++ b/drivers/gidriv.f
@@ -78,7 +78,7 @@ C
 C Note: for 64-bit operating systems, change the following 
 C declaration to INTEGER*8:
 C
-      INTEGER PIXMAP, WORK
+      INTEGER*8 PIXMAP, WORK
 C
       SAVE UNIT, IC, CTABLE, NPICT, MAXIDX, BX, BY, PIXMAP, FILENM
       SAVE CDEFLT, STATE
diff --git a/makemake b/makemake
index e48455e..6a4b1ee 100755
--- a/makemake
+++ b/makemake
@@ -1045,10 +1045,10 @@ pgbind: $(SRC)/cpg/pgbind.c
 libcpgplot.a cpgplot.h: $(PG_SOURCE) pgbind 
 	./pgbind $(PGBIND_FLAGS) -h -w $(PG_SOURCE)
 	$(CCOMPL) -c $(CFLAGC) cpg*.c
-	rm -f cpg*.c
+#	rm -f cpg*.c
 	ar ru libcpgplot.a cpg*.o
 	$(RANLIB) libcpgplot.a
-	rm -f cpg*.o
+#	rm -f cpg*.o
 
 cpgdemo: cpgplot.h $(SRC)/cpg/cpgdemo.c libcpgplot.a
 	$(CCOMPL) $(CFLAGD) -c -I. $(SRC)/cpg/cpgdemo.c
diff --git a/sys_linux/g77_gcc.conf b/sys_linux/g77_gcc.conf
index d6b73e6..b594748 100644
--- a/sys_linux/g77_gcc.conf
+++ b/sys_linux/g77_gcc.conf
@@ -34,13 +34,13 @@
 # Mandatory.
 # The FORTRAN compiler to use.
  
-   FCOMPL="g77"
+   FCOMPL="gfortran"
 
 # Mandatory.
 # The FORTRAN compiler flags to use when compiling the pgplot library.
 # (NB. makemake prepends -c to $FFLAGC where needed)
  
-   FFLAGC="-u -Wall -fPIC -O"
+   FFLAGC="-ffixed-form -ffixed-line-length-none -Wall -fPIC -O"
 
 # Mandatory.
 # The FORTRAN compiler flags to use when compiling fortran demo programs.
@@ -103,7 +103,7 @@
 # Optional: Needed on systems that support shared libraries.
 # The name to give the shared pgplot library.
  
-   SHARED_LIB="libpgplot.so"
+#   SHARED_LIB="libpgplot.so"
 
 # Optional: Needed if SHARED_LIB is set.
 # How to create a shared library from a trailing list of object files.
