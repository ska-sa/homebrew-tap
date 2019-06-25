class Casacore < Formula
  desc "Suite of C++ libraries for radio astronomy data processing"
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v3.1.1.tar.gz"
  sha256 "85d2b17d856592fb206b17e0a344a29330650a4269c80b87f8abb3eaf3dadad4"
  head "https://github.com/casacore/casacore.git"

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "wcslib"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "gcc"  # for gfortran
  depends_on "python" => :recommended
  depends_on "boost-python"
  depends_on "numpy"
  depends_on "casacore-data"

  if build.with?("python")
    depends_on "boost-python3"
  end

  patch :DATA

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCMAKE_SHARED_LINKER_FLAGS='-undefined dynamic_lookup'"
    cmake_args << "-DCMAKE_MODULE_LINKER_FLAGS='-undefined dynamic_lookup'"
    cmake_args << "-DBUILD_PYTHON=ON"
    cmake_args << "-DBUILD_PYTHON3=ON" if build.with? "python"
    cmake_args << "-DUSE_FFTW3=ON" << "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << "-DUSE_HDF5=ON" << "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << "-DUSE_THREADS=ON" << "-DDATA_DIR=#{HOMEBREW_PREFIX}/share/casacore/data"
    system "cmake", "../..", *cmake_args
    system "make", "install"
  end

  test do
    system bin/"findmeastable", "IGRF"
    system bin/"findmeastable", "DE405"
  end
end

__END__
diff --git a/python/CMakeLists-cmake3.12.txt b/python/CMakeLists-cmake3.12.txt
index 7c981f7..49c89cc 100644
--- a/python/CMakeLists-cmake3.12.txt
+++ b/python/CMakeLists-cmake3.12.txt
@@ -60,7 +60,7 @@ Converters/PycValueHolder.h
 Converters/PycArray.tcc
 )
 
-target_link_libraries (casa_python casa_casa ${PYTHON2_Boost_LIBRARIES} ${PYTHON2_LIBRARIES} ${CASACORE_ARCH_LIBS})
+target_link_libraries (casa_python casa_casa ${PYTHON2_Boost_LIBRARIES} ${CASACORE_ARCH_LIBS})
 
 install (TARGETS casa_python
 RUNTIME DESTINATION bin
diff --git a/python3/CMakeLists-cmake3.12.txt b/python3/CMakeLists-cmake3.12.txt
index 26d5ca5..8db7fec 100644
--- a/python3/CMakeLists-cmake3.12.txt
+++ b/python3/CMakeLists-cmake3.12.txt
@@ -51,7 +51,7 @@ add_library (casa_python3
 )
 
 
-target_link_libraries (casa_python3 casa_casa ${PYTHON3_Boost_LIBRARIES} ${PYTHON3_LIBRARIES})
+target_link_libraries (casa_python3 casa_casa ${PYTHON3_Boost_LIBRARIES})
 
 install (TARGETS casa_python3
 RUNTIME DESTINATION bin
diff --git a/python/Converters/test/CMakeLists.txt b/python/Converters/test/CMakeLists.txt
index 32214a8..321c98b 100644
--- a/python/Converters/test/CMakeLists.txt
+++ b/python/Converters/test/CMakeLists.txt
@@ -1,6 +1,6 @@
 include_directories ("..")
 add_library(tConvert MODULE tConvert.cc)
 SET_TARGET_PROPERTIES(tConvert PROPERTIES PREFIX "_") 
-target_link_libraries (tConvert casa_python ${PYTHON_LIBRARIES})
+target_link_libraries (tConvert casa_python)
 add_test (tConvert ${CMAKE_SOURCE_DIR}/cmake/cmake_assay ./tConvert)
 add_dependencies(check tConvert)
