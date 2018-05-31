require 'formula'

class Makems < Formula
  desc 'Make CASA MeasurementSets from scratch'
  homepage 'https://github.com/ska-sa/meqtrees/wiki/BuildingMakeMs'
  url 'https://svn.astron.nl/makems/release/makems/release-1.2.0'
  head 'https://svn.astron.nl/makems/trunk/makems'

  depends_on 'cmake' => :build
  depends_on 'casacore'

  # Darwin does not have /usr/include/malloc.h
  # Darwin already defines 'union semun' in sys/sem.h
  patch :DATA

  def install
    # To get a build type besides "gnu_opt" we need to change from superenv to std env first
    build_type = 'gnu_opt'
    mkdir_p "LOFAR/build/#{build_type}"
    cd "LOFAR/build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete '-DCMAKE_BUILD_TYPE=None'
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCMAKE_MODULE_PATH:PATH=#{Dir.pwd}/../../../LOFAR/CMake"
    cmake_args << '-DUSE_LOG4CPLUS=OFF' << '-DBUILD_TESTING=OFF'
    system 'cmake', '../..', *cmake_args
    system 'make'
    bin.install 'CEP/MS/src/makems'
    cd '../../../doc'
    doc.install 'makems.pdf', 'examples', 'mkant'
    bin.install "#{doc}/mkant/mkant.py"
  end

  test do
    mktemp do
      # Create MS and convert to FITS to verify file structure
      cp_r ["#{doc}/examples/WSRT_ANTENNA", "#{doc}/examples/makems.cfg"], '.'
      system '#{bin}/makems makems.cfg'
      system '#{bin}/ms2uvfits in=test.MS_p0 out=test.fits writesyscal=F'
      if File.exists? 'test.fits' then
        ohai 'makems OK'
      else
        onoe 'makems FAILED'
      end
    end
  end
end

__END__
diff --git a/LOFAR/LCS/Common/src/CMakeLists.txt b/LOFAR/LCS/Common/src/CMakeLists.txt
index 8ab0297..c4badbc 100644
--- a/LOFAR/LCS/Common/src/CMakeLists.txt
+++ b/LOFAR/LCS/Common/src/CMakeLists.txt
@@ -73,8 +73,7 @@ if(HAVE_SHMEM)
     -DMORECORE=shmbrk
     -DMORECORE_CONTIGUOUS=0
     -DMORECORE_CANNOT_TRIM=1
-    -DSHMEM_ALLOC
-    -DHAVE_USR_INCLUDE_MALLOC_H)
+    -DSHMEM_ALLOC)
   join_arguments(shmem_COMPILE_FLAGS)
   set_source_files_properties(${shmem_LIB_SRCS} 
     PROPERTIES COMPILE_FLAGS ${shmem_COMPILE_FLAGS})
diff --git a/LOFAR/LCS/Common/src/shmem/Makefile.am b/LOFAR/LCS/Common/src/shmem/Makefile.am
index fa7fe72..9ae2060 100644
--- a/LOFAR/LCS/Common/src/shmem/Makefile.am
+++ b/LOFAR/LCS/Common/src/shmem/Makefile.am
@@ -13,8 +13,7 @@ AM_CPPFLAGS = \
 	-DMORECORE=shmbrk \
 	-DMORECORE_CONTIGUOUS=0 \
 	-DMORECORE_CANNOT_TRIM=1 \
-	-DSHMEM_ALLOC \
-	-DHAVE_USR_INCLUDE_MALLOC_H 
+	-DSHMEM_ALLOC
 
 libshmem_la_SOURCES = 				\
 	$(DOCHDRS)				\
diff --git a/LOFAR/LCS/Common/src/shmem/shmem_alloc.cc b/LOFAR/LCS/Common/src/shmem/shmem_alloc.cc
index fefc086..9ca31e0 100644
--- a/LOFAR/LCS/Common/src/shmem/shmem_alloc.cc
+++ b/LOFAR/LCS/Common/src/shmem/shmem_alloc.cc
@@ -41,10 +41,10 @@
 
 using LOFAR::map;
 
-// needs to be defined
-union semun {
-    int val;
-};
+// already defined in <sys/sem.h>
+// union semun {
+//     int val;
+// };
 
 /* definitions */
 #define SHMID_REGISTRY_INITIAL_SIZE 32
