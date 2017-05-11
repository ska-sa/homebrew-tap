class Libair < Formula
  desc "Atmospheric inference for phase correction of ALMA data using WVR"
  homepage "http://www.mrao.cam.ac.uk/~bn204/alma/sweng/libairbuild.html"
  url "http://www.mrao.cam.ac.uk/~bn204/soft/libair-1.2.tar.bz2"
  sha256 "aa639c0be126bcc8f0c40af3fa53e40628cd659d873a9cd03d028b6cc9b314e7"

  depends_on "boost"
  depends_on "bnmin1"
  depends_on "pkg-config" => :build

  def patches
    # Patch 1: Allow the use of SWIG 2.x for Python bindings
    # Patch 2: Fix C++ implicit instantiation error
    # Patch 3: Fix const problem with comparison operator
    DATA
  end

  def install
    ENV.deparallelize
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--disable-pybind"
    system "make", "install"
  end

  test do
    system "#{bin}/wvrretrieve", "--help"
  end
end

__END__
diff --git a/pybind/configure b/pybind/configure
index 828ea58..0d06394 100755
--- a/pybind/configure
+++ b/pybind/configure
@@ -15462,9 +15462,9 @@ $as_echo "$swig_version" >&6; }
                         if test -z "$available_patch" ; then
                                 available_patch=0
                         fi
-                        if test $available_major -ne $required_major \
-                                -o $available_minor -ne $required_minor \
-                                -o $available_patch -lt $required_patch ; then
+                        if test $available_major -lt $required_major \
+                                -o $available_major -eq $required_major -a $available_minor -lt $required_minor \
+                                -o $available_major -eq $required_major -a $available_minor -eq $required_minor -a $available_patch -lt $required_patch ; then
                                 { $as_echo "$as_me:${as_lineno-$LINENO}: WARNING: SWIG version >= 1.3.31 is required.  You have $swig_version.  You should look at http://www.swig.org" >&5
 $as_echo "$as_me: WARNING: SWIG version >= 1.3.31 is required.  You have $swig_version.  You should look at http://www.swig.org" >&2;}
                                 SWIG='echo "Error: SWIG version >= 1.3.31 is required.  You have '"$swig_version"'.  You should look at http://www.swig.org" ; false'
diff --git a/src/model_water.hpp b/src/model_water.hpp
index a8d1d3d..fc792c7 100644
--- a/src/model_water.hpp
+++ b/src/model_water.hpp
@@ -182,6 +182,9 @@ namespace LibAIR {
 
   }
 
+  // Declare explicit specialization before implicit instantiation below
+  template<> const double WaterModel<ICloudyWater>::tau_bump;
+
   template<>   inline 
   void WaterModel<ICloudyWater>::dTdTau (std::vector<double> &res) const
   {


diff --git a/src/radiometer_utils.cpp b/src/radiometer_utils.cpp
index 9a995d0..6e83060 100644
--- a/src/radiometer_utils.cpp
+++ b/src/radiometer_utils.cpp
@@ -38,7 +38,7 @@ namespace LibAIR {
       return ( f_i == f_end  );
     }
 
-    bool operator< (  const RadioIter & other )
+    bool operator< (  const RadioIter & other ) const
     {
       if (atend())
       {
