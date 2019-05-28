class Casacore < Formula
  desc "Suite of C++ libraries for radio astronomy data processing"
  homepage "https://github.com/casacore/casacore"
  url "https://github.com/casacore/casacore/archive/v3.1.0.tar.gz"
  sha256 "a6adf2d77ad0d6f32995b1e297fd88d31ded9c3e0bb8f28966d7b35a969f7897"
  head "https://github.com/casacore/casacore.git", :branch => "improve-cmake-findpython"

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

  stable do
    patch do
      # casacore/casacore#846: Boost Python upstream fix
      # Use FindPython2 and FindPython3 modules introduced in cmake 3.12
      url "https://gist.githubusercontent.com/ludwigschwardt/f22e09d458aebd84c59de3013d0671ec/raw/6105f7497548a74dbe24285884cfda6127ca5526/casacore-improve-cmake-findpython-3.1.0.patch"
      sha256 "ecd3526240ee31896afee31f1c2d8e6fb749bca9c2eeb4e578d2f3dcd217c12c"
    end
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
