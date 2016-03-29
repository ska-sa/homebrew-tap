class Casacore < Formula
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v2.1.0.tar.gz"
  sha256 "9c0017e741c1c4b14bc09582867910f750cd76ff2673e0ecd554aa5b2db7acb4"
  head "https://github.com/casacore/casacore.git"

  bottle do
    root_url "https://bintray.com/artifact/download/casacore/homebrew-bottles/"
    sha256 "d3addee413010f7e2e5827c07c1c645c64b41b3abcddf56ce45924283a36d2fa" => :el_capitan
  end

  option "with-cxx11", "Build with C++11 support"

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "homebrew/science/wcslib"
  depends_on "python" => :recommended
  depends_on "python3" => :optional
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "casacore-data"
  depends_on :fortran

  if build.with?('python3')
      depends_on 'boost-python' => ['with-python3']
      depends_on "homebrew/python/numpy" => ['with-python3']
  elsif build.with?('python')
      depends_on 'boost-python'
      depends_on "homebrew/python/numpy"
  end

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCXX11=ON" if build.with? "cxx11"
    
    if build.with? "python"
      cmake_args << "-DBUILD_PYTHON=ON"
      cmake_args << "-DPYTHON2_EXECUTABLE=/usr/local/bin/python2"
      cmake_args << "-DPYTHON2_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/2.7/lib/libpython2.7.dylib"
    else
      cmake_args << "-DBUILD_PYTHON=OFF"
    end
 
    if build.with? "python3"
      cmake_args << "-DBUILD_PYTHON3=ON"
      cmake_args << "-DPYTHON3_EXECUTABLE=/usr/local/bin/python3"
      cmake_args << "-DPYTHON3_LIBRARY=/usr/local/Frameworks/Python.framework/Versions/3.5/lib/libpython3.5.dylib"
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
