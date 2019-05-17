class Casacore < Formula
  desc "Suite of C++ libraries for radio astronomy data processing"
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v3.0.0.tar.gz"
  sha256 "6f0e68fd77b5c96299f7583a03a53a90980ec347bff9dfb4c0abb0e2933e6bcb"
  head "https://github.com/casacore/casacore.git"

  depends_on "cmake" => :build
  depends_on "cfitsio"
  depends_on "wcslib"
  depends_on "python@2" => :optional
  depends_on "python" => :recommended
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "readline"
  depends_on "casacore-data"
  depends_on "gcc"  # for gfortran

  if build.with?("python@2")
    depends_on "boost-python"
    depends_on "numpy"
  end

  if build.with?("python")
    depends_on "boost-python3" => "with-python"
    depends_on "numpy"
  end

  stable do
    patch do
      # casacore/casacore#846: Boost Python upstream fix (remove on next release)
      url "https://gist.githubusercontent.com/ludwigschwardt/bfbe9dd2538abbbf22552fde40bec935/raw/250aff71b76bb7851b02faa88f99642d55f5db44/casacore-patch-boost-pythonxy.patch"
      sha256 "99661f5f9132dae77bc83ae1d1d01785c0ab40a1b78956d3304d243532370784"
    end
  end

  patch do
    # Use FindPython2 and FindPython3 modules introduced in cmake 3.12
    url "https://gist.githubusercontent.com/ludwigschwardt/0bfaef7b2c6832fb018332742e14924e/raw/85002935f06cc821b9bda8246f5a950220e23f9e/casacore-cmake-findpython.patch"
    sha256 "602a5e4728e972167575f39cfc451d91a0c9121b1b247b6eff8e480ccb96b791"
  end

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = "release"
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete "-DCMAKE_BUILD_TYPE=None"
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCMAKE_SHARED_LINKER_FLAGS='-undefined dynamic_lookup'"

    cmake_args << "-DBUILD_PYTHON=ON" if build.with? "python@2"
    cmake_args << "-DBUILD_PYTHON=OFF" if build.without? "python@2"
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
