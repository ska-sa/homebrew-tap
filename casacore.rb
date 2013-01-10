require 'formula'

class Casacore < Formula
  homepage 'http://code.google.com/p/casacore/'
  url 'http://casacore.googlecode.com/files/casacore-1.4.0.tar.bz2'
  md5 '85e708b03e73332bbf584310e49a7a2b'
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
    ENV.j1
    ENV.fortran
    mkdir_p 'build/opt'
    cd 'build/opt'
    system 'cmake', '../..', '-DUSE_FFTW3=ON', "-DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX}",
           '-DUSE_HDF5=ON', "-DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX}", '-DUSE_THREADS=ON',
           '-DDATA_DIR=/usr/local/share/casacore/data', *std_cmake_args
    inreplace 'tables/CMakeFiles/casa_tables.dir/build.make', 'RehordGram', 'RecordGram'
    inreplace 'tables/CMakeFiles/casa_tables.dir/cmake_clean.cmake', 'RehordGram', 'RecordGram'
    inreplace 'tables/CMakeFiles/casa_tables.dir/DependInfo.cmake', 'RehordGram', 'RecordGram'
    inreplace 'ms/CMakeFiles/casa_ms.dir/build.make', 'MSShanGram', 'MSScanGram'
    inreplace 'ms/CMakeFiles/casa_ms.dir/cmake_clean.cmake', 'MSShanGram', 'MSScanGram'
    inreplace 'ms/CMakeFiles/casa_ms.dir/DependInfo.cmake', 'MSShanGram', 'MSScanGram'
    system "make install"
  end
end
