require 'formula'

class Casacore < Formula
  homepage 'http://code.google.com/p/casacore/'
  url 'http://casacore.googlecode.com/files/casacore-1.5.0.tar.bz2'
  sha1 'dca7a451c02b141b9e338ba4ffa713693693ce42'
  head 'http://casacore.googlecode.com/svn/trunk'

  depends_on 'cmake'
  depends_on 'cfitsio'
  depends_on 'wcslib'
  depends_on 'fftw'
  depends_on 'hdf5'
  depends_on 'readline'

  fails_with :clang do
    build 421
    cause <<-EOS.undent
      CMake reports: Don't know how to enable thread support for /usr/bin/clang
      EOS
  end

  def install
    ENV.fortran
    mkdir_p 'build/opt'
    cd 'build/opt'
    system 'cmake', '../..', '-DUSE_FFTW3=ON', "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}",
           '-DUSE_HDF5=ON', "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}", '-DUSE_THREADS=ON',
           '-DDATA_DIR=/usr/local/share/casacore/data', *std_cmake_args
    system "make install"
  end
end
