class Casacore < Formula
  desc "Suite of C++ libraries for radio astronomy data processing"
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v3.0.0.tar.gz"
  sha256 "6f0e68fd77b5c96299f7583a03a53a90980ec347bff9dfb4c0abb0e2933e6bcb"
  head "https://github.com/casacore/casacore.git"

  option "without-cxx11", "Build without C++11 support"

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "brewsci/science/wcslib"
  depends_on "python@2" => :optional
  depends_on "python" => :recommended
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "casacore-data"
  #depends_on "gcc"

  if build.with?("python@2")
    depends_on "boost-python"
    depends_on "numpy"
  end

  if build.with?("python")
    depends_on "boost-python" => "with-python"
    depends_on "numpy"
  end

  # casacore/casacore#846: Boost Python upstream fix (remove on next release)
  patch :DATA

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCXX11=False" if build.without? "cxx11"

    if build.with? "python@2"
      cmake_args << "-DBUILD_PYTHON=ON"
      cmake_args << "-DPYTHON2_EXECUTABLE=/usr/local/bin/python2"
      cmake_args << "-DPYTHON2_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/2.7/lib/libpython2.7.dylib"
    else
      cmake_args << "-DBUILD_PYTHON=OFF"
    end

    if build.with? "python"
      cmake_args << "-DBUILD_PYTHON3=ON"
      cmake_args << "-DPYTHON3_EXECUTABLE=/usr/local/bin/python3"
      cmake_args << "-DPYTHON3_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/3.7/lib/libpython3.7.dylib"
    end

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
diff --git a/python/CMakeLists.txt b/python/CMakeLists.txt
index f8ece2584..3c7b621db 100644
--- a/python/CMakeLists.txt
+++ b/python/CMakeLists.txt
@@ -22,7 +22,15 @@ set(Python_FIND_VERSION 2)
 set(PythonInterp_FIND_VERSION_MAJOR 2)
 find_package(Python REQUIRED)
 if (PYTHONINTERP_FOUND)
-    find_package(Boost REQUIRED COMPONENTS python)
+    find_package(Boost REQUIRED)
+    if (${Boost_MAJOR_VERSION} STREQUAL 1 AND ${Boost_MINOR_VERSION} STRGREATER 66)
+        # Boost>1.67 Python components require a Python version suffix
+        set(BOOST_PYTHON_SEARCH_VERSION python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR})
+    else ()
+        set(BOOST_PYTHON_SEARCH_VERSION python)
+    endif ()
+    find_package(Boost REQUIRED COMPONENTS ${BOOST_PYTHON_SEARCH_VERSION})
+
     find_package (NUMPY REQUIRED)
 
     # copy the variables to their final destination
diff --git a/python3/CMakeLists.txt b/python3/CMakeLists.txt
index 43003659b..ac7fd6924 100644
--- a/python3/CMakeLists.txt
+++ b/python3/CMakeLists.txt
@@ -23,12 +23,14 @@ set(Python_ADDITIONAL_VERSIONS 3.5 3.4)
 find_package(Python REQUIRED)
 
 if (PYTHONINTERP_FOUND)
-    if (APPLE)
-        find_package(Boost REQUIRED COMPONENTS python3)
+    find_package(Boost REQUIRED)
+    if (${Boost_MAJOR_VERSION} STREQUAL 1 AND ${Boost_MINOR_VERSION} STRGREATER 66)
+        # Boost>1.67 Python components require a Python version suffix
+        set(BOOST_PYTHON_SEARCH_VERSION python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR})
     else ()
-        # NOTE: the name of the python3 version of boost is probably Debian/Ubuntu specific
-        find_package(Boost REQUIRED COMPONENTS python-py${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR})
-    endif (APPLE)
+        set(BOOST_PYTHON_SEARCH_VERSION python${PYTHON_VERSION_MAJOR})
+    endif ()
+    find_package(Boost REQUIRED COMPONENTS ${BOOST_PYTHON_SEARCH_VERSION})
 
     find_package (NUMPY REQUIRED)
 
