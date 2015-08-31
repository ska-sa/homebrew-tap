class Casacore < Formula
  homepage "https://github.com/casacore/casacore/wiki"
  url "https://github.com/casacore/casacore/archive/v2.0.3.tar.gz"
  sha256 "44746633113e16f8daabb38c404d2b316b1acfd9304a4df91cb1849d2786d726"
  head "https://github.com/casacore/casacore.git"

  option "without-python", "Don't build with Python support (pyrap and python-casacore won't work though)"
  option "with-cxx11", "Build with C++11 support"

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "wcslib"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "casacore-data"
  depends_on :fortran

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCXX11=ON" if build.with? "cxx11"
    cmake_args << "-DBUILD_PYTHON=ON" if build.with? "python"
    cmake_args << "-DPYTHON_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/Current/lib/libpython2.7.dylib"
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
