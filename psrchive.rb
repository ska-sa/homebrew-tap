class Psrchive < Formula
  desc 'A C++ development library for the analysis of pulsar astronomical data'
  homepage "https://psrchive.sourceforge.io/"

  stable do
    url "https://downloads.sourceforge.net/psrchive/psrchive-2012-12.tar.gz"
    sha256 "0ca685b644eae34cac6dcbbc56b3729f58d334cee94322b38ec98d26c8b9bb71"
    # 1. Add missing include for mem_fun and bind2nd
    # 2. Use 'template' keyword to treat 'get' as a dependent template name
    # 3 - 6. Fix unqualified lookup in templates for overloaded operators
    # 7. Put default arguments in function declaration only
    patch :DATA
  end

  head do
    url "git://git.code.sf.net/p/psrchive/code"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build

    patch :DATA
  end

  option "with-x11", "Experimental: build with x11 support"
  
  if build.with? "x11"
    depends_on "libx11" => :recommended
  end
  
  depends_on "gcc"

  depends_on "pgplot"
  depends_on "fftw"
  depends_on "cfitsio"

  def install
    ENV.deparallelize
    # Force clang to use the old standard library for now (solves issue with mutex type)
    ENV.append "CXXFLAGS", "-stdlib=libstdc++" if ENV.compiler == :clang

    system "./bootstrap" if build.head?
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system bin/"psrchive", "--version"
  end
end

# diff --git a/Util/genutil/templates.h b/Util/genutil/templates.h
# index 88ce0fc..a8e2952 100644
# --- a/Util/genutil/templates.h
# +++ b/Util/genutil/templates.h
# @@ -11,6 +11,7 @@
#  #include <algorithm>
# +#include <functional>
#  #include <iterator>
#  #include <vector>
#
#  #include <assert.h>
#  #include <string.h>
# --- a/Base/Formats/PSRFITS/setup_profiles.h
# +++ b/Base/Formats/PSRFITS/setup_profiles.h
# @@ -32,7 +32,7 @@ void setup_profiles_dat (I subint, P& profiles)
#  template<class E, typename I, typename P>
#  void setup_profiles (I subint, P& profiles)
#  {
# -  E* ext = subint->get_Profile(0,0)->Pulsar::Profile::get<E>();
# +  E* ext = subint->get_Profile(0,0)->template get<E>();
#    if (!ext)
#      throw Error (InvalidState, "setup_profiles<Extension>",
#       "first profile is missing required Extension");
# @@ -44,7 +44,7 @@ void setup_profiles (I subint, P& profiles)
#
#    for (unsigned ichan=0; ichan<nchan; ichan++)
#    {
# -    ext = subint->get_Profile(0,ichan)->Pulsar::Profile::get<E>();
# +    ext = subint->get_Profile(0,ichan)->template get<E>();
#      if (!ext)
#        throw Error (InvalidState, "setup_profiles<Extension>",
#         "profile[%u] is missing required Extension", ichan);
__END__
diff --git a/Util/genutil/Types.h b/Util/genutil/Types.h
index 78a0154..13f10dd 100644
--- a/Util/genutil/Types.h
+++ b/Util/genutil/Types.h
@@ -123,16 +123,16 @@ namespace Signal {
   //! Returns the state resulting from a pscrunch operation
   State pscrunch (State state);
 
-}
+  std::ostream& operator<< (std::ostream& ostr, Signal::Source source);
+  std::istream& operator>> (std::istream& is, Signal::Source& source);
 
-std::ostream& operator << (std::ostream& ostr, Signal::Source source);
-std::istream& operator >> (std::istream& is, Signal::Source& source);
+  std::ostream& operator<< (std::ostream& ostr, Signal::State state);
+  std::istream& operator>> (std::istream& is, Signal::State& state);
 
-std::ostream& operator << (std::ostream& ostr, Signal::State state);
-std::istream& operator >> (std::istream& is, Signal::State& state);
+  std::ostream& operator<< (std::ostream& ostr, Signal::Scale scale);
+  std::istream& operator>> (std::istream& is, Signal::Scale& scale);
 
-std::ostream& operator << (std::ostream& ostr, Signal::Scale scale);
-std::istream& operator >> (std::istream& is, Signal::Scale& scale);
+}
 
 /* note that Basis extraction and insertion operators are defined in
    Conventions.h */
diff --git a/Util/genutil/Types.C b/Util/genutil/Types.C
index 682c29e..470d8ba 100644
--- a/Util/genutil/Types.C
+++ b/Util/genutil/Types.C
@@ -232,12 +232,12 @@ Signal::State Signal::string2State (const string& ss)
 	       "Unknown state '" + ss + "'");
 }
 
-std::ostream& operator<< (std::ostream& ostr, Signal::State state)
+std::ostream& Signal::operator << (std::ostream& ostr, Signal::State state)
 {
   return ostr << State2string(state);
 }
 
-std::istream& operator >> (std::istream& is, Signal::State& state)
+std::istream& Signal::operator >> (std::istream& is, Signal::State& state)
 {
   return extraction (is, state, Signal::string2State);
 }
@@ -294,12 +294,12 @@ Signal::Source Signal::string2Source (const string& ss)
 	       "Unknown source '" + ss + "'");
 }
 
-std::ostream& operator<< (std::ostream& ostr, Signal::Source source)
+std::ostream& Signal::operator << (std::ostream& ostr, Signal::Source source)
 {
   return ostr << Source2string(source);
 }
 
-std::istream& operator >> (std::istream& is, Signal::Source& source)
+std::istream& Signal::operator >> (std::istream& is, Signal::Source& source)
 {
   return extraction (is, source, Signal::string2Source);
 }
@@ -353,12 +353,12 @@ Signal::Scale Signal::string2Scale (const string& ss)
 	       "Unknown scale '" + ss + "'");
 }
 
-std::ostream& operator<< (std::ostream& ostr, Signal::Scale scale)
+std::ostream& Signal::operator << (std::ostream& ostr, Signal::Scale scale)
 {
   return ostr << Scale2string(scale);
 }
 
-std::istream& operator >> (std::istream& is, Signal::Scale& scale)
+std::istream& Signal::operator >> (std::istream& is, Signal::Scale& scale)
 {
   return extraction (is, scale, Signal::string2Scale);
 }
diff --git a/Util/tempo/Pulsar/Predictor.h b/Util/tempo/Pulsar/Predictor.h
index 7e774ee..c0cd789 100644
--- a/Util/tempo/Pulsar/Predictor.h
+++ b/Util/tempo/Pulsar/Predictor.h
@@ -99,10 +99,10 @@ namespace Pulsar {
 
   };
 
-}
+  std::ostream& operator<< (std::ostream& ostr, Pulsar::Predictor::Policy p);
 
-std::ostream& operator<< (std::ostream& ostr, Pulsar::Predictor::Policy p);
+  std::istream& operator>> (std::istream& istr, Pulsar::Predictor::Policy& p);
 
-std::istream& operator>> (std::istream& istr, Pulsar::Predictor::Policy& p);
+}
 
 #endif
diff --git a/Util/resources/Generator_default.C b/Util/resources/Generator_default.C
index 3df6f76..33117b8 100644
--- a/Util/resources/Generator_default.C
+++ b/Util/resources/Generator_default.C
@@ -13,7 +13,7 @@
 
 using namespace std;
 
-std::ostream& operator<< (std::ostream& ostr, Pulsar::Predictor::Policy p)
+std::ostream& Pulsar::operator<< (std::ostream& ostr, Pulsar::Predictor::Policy p)
 {
   if (p == Pulsar::Predictor::Input)
     return ostr << "input";
@@ -27,7 +27,7 @@ std::ostream& operator<< (std::ostream& ostr, Pulsar::Predictor::Policy p)
   return ostr;
 }
 
-std::istream& operator>> (std::istream& istr, Pulsar::Predictor::Policy& p)
+std::istream& Pulsar::operator>> (std::istream& istr, Pulsar::Predictor::Policy& p)
 {
   std::string policy;
   istr >> policy;
diff --git a/Base/Formats/PSRFITS/setup_profiles.h b/Base/Formats/PSRFITS/setup_profiles.h
index 29fa2f2..f6bdaae 100644
diff --git a/Util/genutil/RobustStats.h b/Util/genutil/RobustStats.h
index 6be7634..cd5424a 100644
--- a/Util/genutil/RobustStats.h
+++ b/Util/genutil/RobustStats.h
@@ -126,7 +126,7 @@ T f_pseudosigma ( T f_spread )
  * @param[in] Tukey_tune is the tuning constant for the influence function (Tukey's biweight in this case). This affects the efficiency of the estimator. The optimal value is 6.0 (i.e. include data up to 4 sigma away from the mean (Data analysis and regression, Mosteller and Tukey 1977)
 */
 template<typename T>
-T robust_stddev ( T * data, unsigned size, T initial_guess, T initial_guess_scale = 1.4826, T Tukey_tune = 6.0 )
+T robust_stddev ( T * data, unsigned size, T initial_guess, T initial_guess_scale, T Tukey_tune )
 {
   vector<T> input;
   input.resize ( size );
