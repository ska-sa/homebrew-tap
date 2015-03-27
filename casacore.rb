require 'formula'

class Casacore < Formula
  homepage 'http://code.google.com/p/casacore/'
  url 'ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-1.7.0.tar.bz2'
  sha1 '03edc1c8b8c3fbee91df4f9874f5db7b9d403035'
  head 'http://casacore.googlecode.com/svn/trunk'

  depends_on 'cmake' => :build
  depends_on 'cfitsio'
  depends_on 'wcslib'
  depends_on 'fftw'
  depends_on 'hdf5'
  depends_on 'readline'
  depends_on 'casacore-data'
  depends_on :fortran

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = 'release'
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete '-DCMAKE_BUILD_TYPE=None'
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCXX11=ON" if ENV.compiler == :clang
    cmake_args << '-DUSE_FFTW3=ON' << "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << '-DUSE_HDF5=ON' << "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << '-DUSE_THREADS=ON' << "-DDATA_DIR=#{HOMEBREW_PREFIX}/share/casacore/data"
    system 'cmake', '../..', *cmake_args
    system "make install"
  end

  def test
    if not system 'findmeastable IGRF' and not system 'findmeastable DE405'
      ohai 'casacore OK'
    end
  end
end
