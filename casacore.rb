require 'formula'

class CasacoreDownloadStrategy < SubversionDownloadStrategy
  def stage
    mkdir_p "casacore"
    cd "casacore"
    super
  end
end

class Casacore < Formula
  homepage 'http://code.google.com/p/casacore/'
  url 'ftp://ftp.atnf.csiro.au/pub/software/casacore/casacore-1.7.0.tar.bz2'
  sha1 '03edc1c8b8c3fbee91df4f9874f5db7b9d403035'
  head 'http://casacore.googlecode.com/svn/trunk'
  devel do
    url 'http://casacore.googlecode.com/svn/branches/nov14/', :using => CasacoreDownloadStrategy
    version "2.0.0dev"
  end

  depends_on 'cmake' => :build
  depends_on 'cfitsio'
  depends_on 'wcslib'
  depends_on 'fftw'
  depends_on 'hdf5'
  depends_on 'readline'
  depends_on 'casacore-data'
  depends_on :fortran

  devel do
    # Fix install bug
    patch :DATA
  end

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

__END__
diff --git a/ms/CMakeLists.txt b/ms/CMakeLists.txt
index 260095d..e7000e6 100644
--- a/ms/CMakeLists.txt
+++ b/ms/CMakeLists.txt
@@ -195,7 +195,6 @@ MeasurementSets/MSMainColumns.h
 MeasurementSets/MSMainEnums.h
 MeasurementSets/MSObsColumns.h
 MeasurementSets/MSObsEnums.h
-MeasurementSets/MSObsIndex.h
 MeasurementSets/MSObservation.h
 MeasurementSets/MSPointing.h
 MeasurementSets/MSPointingColumns.h
@@ -223,11 +222,9 @@ MeasurementSets/MSTable.h
 MeasurementSets/MSTable.tcc
 MeasurementSets/MSTableImpl.h
 MeasurementSets/MSTileLayout.h
-MeasurementSets/MSTimeDefinitions.h
 MeasurementSets/MSWeather.h
 MeasurementSets/MSWeatherColumns.h
 MeasurementSets/MSWeatherEnums.h
-MeasurementSets/MSWeatherIndex.h
 MeasurementSets/MeasurementSet.h
 MeasurementSets/StokesConverter.h
 DESTINATION include/casacore/ms/MeasurementSets
