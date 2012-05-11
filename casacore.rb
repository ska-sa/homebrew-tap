require 'formula'

class Casacore < Formula
  url 'http://casacore.googlecode.com/files/casacore-1.4.0.tar.bz2'
  homepage 'http://code.google.com/p/casacore/'
  md5 '85e708b03e73332bbf584310e49a7a2b'

  depends_on 'cmake'
  depends_on 'cfitsio'
  depends_on 'wcslib'
  depends_on 'fftw'
  depends_on 'hdf5'
  depends_on 'readline'

  fails_with :clang do
    build 318
    cause <<-EOS.undent
      CMake reports: Don't know how to enable thread support for /usr/bin/clang
      EOS
  end

  def install
    ENV.j1
    ENV.fortran
    system "mkdir -p build/opt"
    Dir.chdir("build/opt")
    system "cmake ../.. -DUSE_HDF5=ON -DUSE_FFTW3=ON -DFFTW3_ROOT_DIR=#{HOMEBREW_PREFIX} -DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX} -DCMAKE_INSTALL_PREFIX=#{prefix} -DUSE_THREADS=ON"
    system "/usr/bin/sed -i orig -e 's/RehordGram/RecordGram/g' tables/CMakeFiles/casa_tables.dir/build.make"
    system "/usr/bin/sed -i orig -e 's/RehordGram/RecordGram/g' tables/CMakeFiles/casa_tables.dir/cmake_clean.cmake"
    system "/usr/bin/sed -i orig -e 's/RehordGram/RecordGram/g' tables/CMakeFiles/casa_tables.dir/DependInfo.cmake"
    system "/usr/bin/sed -i orig -e 's/MSShanGram/MSScanGram/g' ms/CMakeFiles/casa_ms.dir/build.make"
    system "/usr/bin/sed -i orig -e 's/MSShanGram/MSScanGram/g' ms/CMakeFiles/casa_ms.dir/cmake_clean.cmake"
    system "/usr/bin/sed -i orig -e 's/MSShanGram/MSScanGram/g' ms/CMakeFiles/casa_ms.dir/DependInfo.cmake"
    system "make install"
  end
end
