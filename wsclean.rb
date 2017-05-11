class Wsclean < Formula
  desc "Fast widefield interferometric imager based on w-stacking"
  homepage "https://sourceforge.net/projects/wsclean/"
  url "https://sourceforge.net/projects/wsclean/files/wsclean-1.7/wsclean-1.7.tar.bz2"
  sha256 "05de05728ace42c3f7cba38e6c0182534d0be5d00b4563501970a9b77a70cd54"

  depends_on "cmake" => :build

  depends_on "casacore"
  depends_on "cfitsio"
  depends_on "fftw"
  depends_on "boost"
  depends_on "gsl"

  # 1. Add <algorithm> for std::min and std::max
  # 2. Change C++0x to C++11 for clang
  # 3. Explicitly define M_PIl (GNU extension) for clang
  # 4. Replace sincos with __sincos (clang extension) but not sincosf and sincosl
  # 5. Replace exp10 with __exp10 (clang extension)
  # 6. Correctly calculate memory size on OS X
  patch :DATA

  def install
    system "cmake", ".", *std_cmake_args
    system "make", "install"
  end

  test do
    system "#{bin}/wsclean", "-version"
  end
end

__END__
diff --git a/aocommon/uvector.h b/aocommon/uvector.h
index 73e25d0..cdb9a23 100644
--- a/aocommon/uvector.h
+++ b/aocommon/uvector.h
@@ -6,6 +6,7 @@
 #include <memory>
 #include <utility>
 #include <stdexcept>
+#include <algorithm>
 
 /**
  * @file uvector.h
diff --git a/aocommon/uvector_03.h b/aocommon/uvector_03.h
index d83f0db..ae6cf90 100644
--- a/aocommon/uvector_03.h
+++ b/aocommon/uvector_03.h
@@ -6,6 +6,7 @@
 #include <memory>
 #include <utility>
 #include <stdexcept>
+#include <algorithm>
 
 /**
  * @file uvector.h
diff --git a/CMakeLists.txt b/CMakeLists.txt
index 7b041a7..b16a6f5 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -62,7 +62,7 @@ IF("${isSystemDir}" STREQUAL "-1")
    SET(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
 ENDIF("${isSystemDir}" STREQUAL "-1")
 
-set(CMAKE_REQUIRED_FLAGS "-std=c++0x")
+set(CMAKE_REQUIRED_FLAGS "-std=c++11")
 include(CheckCXXSourceCompiles)
 check_cxx_source_compiles(
 "#include \"${CMAKE_CURRENT_SOURCE_DIR}/aocommon/uvector.h\"
@@ -107,7 +107,7 @@ ENDIF("${isSystemDir}" STREQUAL "-1")
 
 add_executable(wsclean wscleanmain.cpp wsclean.cpp casamaskreader.cpp dftpredictionalgorithm.cpp fftconvolver.cpp fftresampler.cpp fitsiochecker.cpp fitsreader.cpp fitswriter.cpp imageweights.cpp layeredimager.cpp nlplfitter.cpp modelrenderer.cpp progressbar.cpp stopwatch.cpp wsinversion.cpp cleanalgorithms/cleanalgorithm.cpp cleanalgorithms/joinedclean.cpp cleanalgorithms/moresane.cpp cleanalgorithms/multiscaleclean.cpp cleanalgorithms/simpleclean.cpp model/model.cpp msproviders/contiguousms.cpp msproviders/msprovider.cpp msproviders/partitionedms.cpp ${LBEAM_FILES})
 
-set_target_properties(wsclean PROPERTIES COMPILE_FLAGS "-std=c++0x")
+set_target_properties(wsclean PROPERTIES COMPILE_FLAGS "-std=c++11")
 
 target_link_libraries(wsclean ${CASA_LIBS} ${FFTW3_LIB} ${Boost_FILESYSTEM_LIBRARY} ${Boost_THREAD_LIBRARY} ${Boost_SYSTEM_LIBRARY} ${FITSIO_LIB} ${GSL_LIB} ${CBLAS_LIB} ${PTHREAD_LIB} ${LBEAM_LIBS})
 
diff --git a/radeccoord.h b/radeccoord.h
index 7400d96..f07c5de 100644
--- a/radeccoord.h
+++ b/radeccoord.h
@@ -7,6 +7,9 @@
 #include <cstdlib>
 #include <cmath>
 
+// Specifically for clang
+# define M_PIl          3.1415926535897932384626433832795029L  /* pi */
+
 class RaDecCoord
 {
 	private:
diff --git a/dftpredictionalgorithm.cpp b/dftpredictionalgorithm.cpp
index e2dfec7..7b72cd0 100644
--- a/dftpredictionalgorithm.cpp
+++ b/dftpredictionalgorithm.cpp
@@ -265,7 +265,7 @@ void DFTPredictionAlgorithm::predict(MC2x2& dest, double u, double v, double w,
 	double l = component.L(), m = component.M(), lmsqrt = component.LMSqrt();
 	double angle = 2.0*M_PI*(u*l + v*m + w*(lmsqrt-1.0));
 	double sinangleOverLMS, cosangleOverLMS;
-	sincos(angle, &sinangleOverLMS, &cosangleOverLMS);
+	__sincos(angle, &sinangleOverLMS, &cosangleOverLMS);
 	sinangleOverLMS /= lmsqrt;
 	cosangleOverLMS /= lmsqrt;
 	MC2x2 temp, appFlux;
diff --git a/dftpredictionalgorithm.h b/dftpredictionalgorithm.h
index 9cd2aab..c0297a3 100644
--- a/dftpredictionalgorithm.h
+++ b/dftpredictionalgorithm.h
@@ -99,7 +99,7 @@ private:
 		// Position angle is angle from North:
 		// (TODO this and next statements can be optimized to remove add)
 		double paSin, paCos;
-		sincos(positionAngle+0.5*M_PI, &paSin, &paCos);
+		__sincos(positionAngle+0.5*M_PI, &paSin, &paCos);
 		// Make rotation matrix
 		long double transf[4];
 		transf[0] = paCos;
diff --git a/layeredimager.cpp b/layeredimager.cpp
index 3e5566c..ce3f840 100644
--- a/layeredimager.cpp
+++ b/layeredimager.cpp
@@ -651,7 +651,7 @@ void LayeredImager::projectOnImageAndCorrect(const std::complex<double> *source,
 			
 			double rad = twoPiW * *sqrtLMIter;
 			double s, c;
-			sincos(rad, &s, &c);
+			__sincos(rad, &s, &c);
 			/*std::complex<double> val = std::complex<double>(
 				source->real() * c - source->imag() * s,
 				source->real() * s + source->imag() * c
@@ -725,7 +725,7 @@ void LayeredImager::copyImageToLayerAndInverseCorrect(std::complex<double> *dest
 			
 			double rad = twoPiW * *sqrtLMIter;
 			double s, c;
-			sincos(rad, &s, &c);
+			__sincos(rad, &s, &c);
 			double realVal = dataReal[xDest + yDest*_width];
 			if(IsComplex)
 			{
diff --git a/imagecoordinates.h b/imagecoordinates.h
index bbfcf04..4ccb770 100644
--- a/imagecoordinates.h
+++ b/imagecoordinates.h
@@ -130,13 +130,19 @@ class ImageCoordinates
 		}
 	private:
 		static void SinCos(double angle, double* sinAngle, double* cosAngle)
-		{ sincos(angle, sinAngle, cosAngle); }
+		{ __sincos(angle, sinAngle, cosAngle); }
 		
 		static void SinCos(long double angle, long double* sinAngle, long double* cosAngle)
-		{ sincosl(angle, sinAngle, cosAngle); }
+		{
+			*sinAngle = sin(angle);
+			*cosAngle = cos(angle);
+		}
 		
 		static void SinCos(float angle, float* sinAngle, float* cosAngle)
-		{ sincosf(angle, sinAngle, cosAngle); }
+		{
+			*sinAngle = sin(angle);
+			*cosAngle = cos(angle);
+		}
 		
 		ImageCoordinates();
 };
diff --git a/matrix2x2.h b/matrix2x2.h
index 66f4b2a..41db86c 100644
--- a/matrix2x2.h
+++ b/matrix2x2.h
@@ -262,7 +262,7 @@ public:
 	static void RotationMatrix(std::complex<T>* matrix, double alpha)
 	{
 		T cosAlpha, sinAlpha;
-		sincos(alpha, &sinAlpha, &cosAlpha);
+		__sincos(alpha, &sinAlpha, &cosAlpha);
 		matrix[0] = cosAlpha; matrix[1] = -sinAlpha;
 		matrix[2] = sinAlpha; matrix[3] = cosAlpha;
 	}
diff --git a/wsinversion.cpp b/wsinversion.cpp
index 3b5d9ad..aff3ec7 100644
--- a/wsinversion.cpp
+++ b/wsinversion.cpp
@@ -719,7 +719,7 @@ void WSInversion::rotateVisibilities(const BandData &bandData, double shiftFacto
 	{
 		const double wShiftRad = shiftFactor / bandData.ChannelWavelength(ch);
 		double rotSinD, rotCosD;
-		sincos(wShiftRad, &rotSinD, &rotCosD);
+		__sincos(wShiftRad, &rotSinD, &rotCosD);
 		float rotSin = rotSinD * multFactor, rotCos = rotCosD * multFactor;
 		std::complex<float> v = *dataIter;
 		*dataIter = std::complex<float>(
diff --git a/modelrenderer.cpp b/modelrenderer.cpp
index c284e3e..cc138b1 100644
--- a/modelrenderer.cpp
+++ b/modelrenderer.cpp
@@ -87,7 +87,8 @@ void ModelRenderer::Restore(NumType* imageData, size_t imageWidth, size_t imageH
 	// Make rotation matrix
 	long double transf[4];
 	// Position angle is angle from North: 
-	sincosl(beamPA+0.5*M_PI, &transf[2], &transf[0]);
+	transf[2] = sin(beamPA+0.5*M_PI);
+	transf[0] = cos(beamPA+0.5*M_PI);
 	transf[1] = -transf[2];
 	transf[3] = transf[0];
 	double sigmaMax = std::max(std::fabs(sigmaMaj * transf[0]), std::fabs(sigmaMaj * transf[1]));
@@ -170,7 +171,8 @@ void ModelRenderer::Restore(NumType* imageData, NumType* modelData, size_t image
 	// Make rotation matrix
 	long double transf[4];
 	// Position angle is angle from North: 
-	sincosl(beamPA+0.5*M_PI, &transf[2], &transf[0]);
+	transf[2] = sin(beamPA+0.5*M_PI);
+	transf[0] = cos(beamPA+0.5*M_PI);
 	transf[1] = -transf[2];
 	transf[3] = transf[0];
 	double sigmaMax = std::max(std::fabs(sigmaMaj * transf[0]), std::fabs(sigmaMaj * transf[1]));
diff --git a/imageweights.cpp b/imageweights.cpp
index fc3676f..446e3cd 100644
--- a/imageweights.cpp
+++ b/imageweights.cpp
@@ -212,7 +212,7 @@ void ImageWeights::FinishGridding()
 			for(ao::uvector<double>::const_iterator i=_grid.begin(); i!=_grid.end(); ++i)
 				avgW += *i * *i;
 			avgW /= _totalSum;
-			double numeratorSqrt = 5.0 * exp10(-_weightMode.BriggsRobustness());
+			double numeratorSqrt = 5.0 * __exp10(-_weightMode.BriggsRobustness());
 			double sSq = numeratorSqrt*numeratorSqrt / avgW;
 			for(ao::uvector<double>::iterator i=_grid.begin(); i!=_grid.end(); ++i)
 			{
diff --git a/nlplfitter.cpp b/nlplfitter.cpp
index f67eaba..8a027c7 100644
--- a/nlplfitter.cpp
+++ b/nlplfitter.cpp
@@ -146,7 +146,7 @@ public:
 				fity = a_j + fity * lg;
 			}
 			//std::cout << x << ':' << fity << " / \n";
-			gsl_vector_set(f, i, exp10(fity) - y);
+			gsl_vector_set(f, i, __exp10(fity) - y);
 		}
 			
 		return GSL_SUCCESS;
@@ -171,7 +171,7 @@ public:
 				const double a_j = gsl_vector_get(xvec, j);
 				fity = a_j + fity * lg;
 			}
-			fity = exp10(fity);
+			fity = __exp10(fity);
 			// dY/da_i = e^[ a_0...a_i-1,a_i+1...a_n] * (e^[a_i {log x}^i]) {log x}^i
 			gsl_matrix_set(J, i, 0, fity);
 			
@@ -453,5 +453,5 @@ double NonLinearPowerLawFitter::Evaluate(double x, const std::vector<double>& te
 		size_t j = terms.size()-k-1;
 		y = y * lg + terms[j];
 	}
-	return exp10(y);
+	return __exp10(y);
 }
diff --git a/nlplfitter.h b/nlplfitter.h
index 27d26ec..756f557 100644
--- a/nlplfitter.h
+++ b/nlplfitter.h
@@ -39,7 +39,7 @@ public:
 		
 	static double Term0ToFactor(double term0, double term1)
 	{
-		return exp10(term0); // + term1*log(NLPLFact));
+		return __exp10(term0); // + term1*log(NLPLFact));
 	}
 	
 	static double FactorToTerm0(double factor, double term1)
diff --git a/wsinversion.cpp b/wsinversion.cpp
index aff3ec7..0fd3b72 100644
--- a/wsinversion.cpp
+++ b/wsinversion.cpp
@@ -22,6 +22,11 @@
 
 #include <boost/thread/thread.hpp>
 
+#ifdef __APPLE__
+#include <sys/types.h>
+#include <sys/sysctl.h>
+#endif /* __APPLE__ */
+
 WSInversion::MSData::MSData() : matchingRows(0), totalRowsProcessed(0)
 { }
 
@@ -30,8 +35,14 @@ WSInversion::MSData::~MSData()
 
 WSInversion::WSInversion(ImageBufferAllocator<double>* imageAllocator, size_t threadCount, double memFraction, double absMemLimit) : InversionAlgorithm(), _phaseCentreRA(0.0), _phaseCentreDec(0.0), _phaseCentreDL(0.0), _phaseCentreDM(0.0), _denormalPhaseCentre(false), _hasFrequencies(false), _freqHigh(0.0), _freqLow(0.0), _bandStart(0.0), _bandEnd(0.0), _beamSize(0.0), _totalWeight(0.0), _startTime(0.0), _gridMode(LayeredImager::NearestNeighbour), _cpuCount(threadCount), _laneBufferSize(_cpuCount*2), _imageBufferAllocator(imageAllocator)
 {
-	long int pageCount = sysconf(_SC_PHYS_PAGES), pageSize = sysconf(_SC_PAGE_SIZE);
-	_memSize = (int64_t) pageCount * (int64_t) pageSize;
+#ifdef __APPLE__
+        size_t len = sizeof(_memSize);
+        int ret = sysctlbyname("hw.memsize", &_memSize, &len, NULL, 0);
+#else
+        long int pageCount = sysconf(_SC_PHYS_PAGES), pageSize = sysconf(_SC_PAGE_SIZE);
+        _memSize = (int64_t) pageCount * (int64_t) pageSize;
+#endif /* __APPLE__ */
+
 	double memSizeInGB = (double) _memSize / (1024.0*1024.0*1024.0);
 	if(memFraction == 1.0 && absMemLimit == 0.0) {
 		std::cout << "Detected " << round(memSizeInGB*10.0)/10.0 << " GB of system memory, usage not limited.\n";
@@ -46,7 +57,7 @@ WSInversion::WSInversion(ImageBufferAllocator<double>* imageAllocator, size_t th
 		else
 			std::cout << "limit=" << round(absMemLimit*10.0)/10.0 << "GB)\n";
 		
-		_memSize = int64_t((double) pageCount * (double) pageSize * memFraction);
+		_memSize = int64_t((double) _memSize * memFraction);
 		if(absMemLimit!=0.0 && double(_memSize) > double(1024.0*1024.0*1024.0) * absMemLimit)
 			_memSize = int64_t(double(absMemLimit) * double(1024.0*1024.0*1024.0));
 	}
