require 'formula'

class Casarest < Formula
  homepage 'http://www.astron.nl/meqwiki/LinkingWithCasaCore'
  url 'https://svn.astron.nl/casarest/release/casarest/release-1.2.1'
  head 'https://svn.astron.nl/casarest/trunk/casarest'

  depends_on 'casacore'
  depends_on 'cmake'
  depends_on 'boost'
  depends_on 'readline'
  depends_on 'wcslib'
  depends_on 'hdf5'

  fails_with :clang do
    build 421
    cause <<-EOS.undent
      Code does not follow C++ standard strictly but does whatever GCC allows
      EOS
  end

  def patches
    # Fixes disallowed size_t vs int* comparison, which used to be specially
    # included for Darwin systems, but does not seem relevant anymore.
    # Add boost_system library to avoid missing symbols
    DATA
  end

  def install
    ENV.fortran
    mkdir_p 'build'
    cd 'build'
    cmake_args = std_cmake_args
    cmake_args << "-DCASACORE_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}"
    system 'cmake', '..', *cmake_args
    system "make install"
    mkdir_p "#{prefix}/share/casarest"
    mv '../measures_data', "#{prefix}/share/casarest/data"
  end
end

__END__
diff --git a/msvis/MSVis/AsynchronousTools.cc b/msvis/MSVis/AsynchronousTools.cc
index 81ad733..c442f0d 100644
--- a/msvis/MSVis/AsynchronousTools.cc
+++ b/msvis/MSVis/AsynchronousTools.cc
@@ -508,13 +508,8 @@ Semaphore::Semaphore (int initialValue)
 
         name_p = utilj::format ("/CasaAsync_%03d", i);
         impl_p->semaphore_p = sem_open (name_p.c_str(), O_CREAT | O_EXCL, 0700, initialValue);//new sem_t;
-#ifdef __APPLE__
-        code = (size_t(impl_p->semaphore_p) == SEM_FAILED) ? errno : 0;
-    } while (size_t(impl_p->semaphore_p) == SEM_FAILED && code == EEXIST);
-#else
         code = (impl_p->semaphore_p == SEM_FAILED) ? errno : 0;
     } while (impl_p->semaphore_p == SEM_FAILED && code == EEXIST);
-#endif
 
     ThrowIfError (code, "Semaphore::open: name='" + name_p + "'");
 }
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 9d3be48..208108d 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -38,7 +38,7 @@ find_package(CfitsIO REQUIRED)
 find_package(WcsLib REQUIRED)
 find_package(LAPACK REQUIRED)
 find_package(BLAS REQUIRED)
-find_package(Boost REQUIRED COMPONENTS thread)
+find_package(Boost REQUIRED COMPONENTS thread system)
 find_package(HDF5)
 if(NOT HDF5_FOUND)
     message(STATUS "  HDF5 not used")
