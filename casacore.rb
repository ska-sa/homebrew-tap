class Casacore < Formula
  desc "Suite of C++ libraries for radio astronomy data processing"
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v3.5.0.tar.gz"
  sha256 "63f1c8eff932b0fcbd38c598a5811e6e5397b72835b637d6f426105a183b3f91"
  head "https://github.com/casacore/casacore.git"

  option "with-python", "Build Python bindings"

  depends_on "cmake" => :build
  depends_on "casacore-data"
  depends_on "cfitsio"
  depends_on "fftw"
  depends_on "gcc"  # for gfortran
  depends_on "gsl"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "wcslib"

  patch :DATA

  if build.with?("python")
    depends_on "python3"
    depends_on "numpy"
    depends_on "boost-python3"
  end

  def install
    casacore_data = HOMEBREW_PREFIX / "opt/casacore-data/data"
    opoo "casacore data not found at #{casacore_data}" unless casacore_data.exist?
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir "build/#{build_type}" do
      cmake_args = std_cmake_args
      cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
      cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
      cmake_args << "-DBUILD_PYTHON3=#{build.with?("python") ? "ON" : "OFF"}"
      cmake_args << "-DUSE_OPENMP=OFF"
      cmake_args << "-DUSE_FFTW3=ON" << "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}"
      cmake_args << "-DUSE_HDF5=ON" << "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}"
      cmake_args << "-DBoost_NO_BOOST_CMAKE=True"
      cmake_args << "-DDATA_DIR=#{HOMEBREW_PREFIX / "opt/casacore-data/data"}"
      system "cmake", "../..", *cmake_args
      system "make", "install"
    end
  end

  test do
    system bin / "findmeastable", "IGRF"
    system bin / "findmeastable", "DE405"
  end
end

__END__
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
