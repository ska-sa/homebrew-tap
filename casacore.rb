require 'formula'

class Casacore < Formula
  homepage 'http://code.google.com/p/casacore/'
  url 'http://casacore.googlecode.com/files/casacore-1.5.0.tar.bz2'
  sha1 'dca7a451c02b141b9e338ba4ffa713693693ce42'
  head 'http://casacore.googlecode.com/svn/trunk'

  depends_on 'cmake' => :build
  depends_on 'cfitsio'
  depends_on 'wcslib'
  depends_on 'fftw'
  depends_on 'hdf5'
  depends_on 'readline'
  depends_on 'casacore-data'
  depends_on :fortran

  if not build.head?
    # This CMake compiler detection issue is fixed in HEAD
    fails_with :clang do
      build 425
      cause <<-EOS.undent
        CMake reports: Don't know how to enable thread support for /usr/bin/clang
        EOS
    end
  end

  def install
    # To get a build type besides "release" we need to change from superenv to std env first
    build_type = 'release'
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete '-DCMAKE_BUILD_TYPE=None'
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << '-DUSE_FFTW3=ON' << "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << '-DUSE_HDF5=ON' << "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}"
    cmake_args << '-DUSE_THREADS=ON' << '-DDATA_DIR=/usr/local/share/casacore/data'
    system 'cmake', '../..', *cmake_args
    system "make install"
  end

  def test
    if not system 'findmeastable IGRF' and not system 'findmeastable DE405'
      ohai 'casacore OK'
    end
  end
end
