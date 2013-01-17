require 'formula'

class Meqtrees < Formula
  homepage 'http://www.astron.nl/meqwiki/MeqTrees'
  url 'https://svn.astron.nl/MeqTrees/release/Timba/release-1.2.1'
  head 'https://svn.astron.nl/MeqTrees/trunk/Timba'

  option 'enable-debug', 'Enable debug build of MeqTrees as well as debugging symbols'
  option 'without-symbols', 'Remove debugging symbols'

  # Since MeqTrees is still quite experimental we want debug symbols
  # included, which are aggressively stripped out in superenv.
  env :std

  depends_on 'cmake' => :build
  depends_on 'casacore'
  depends_on 'pyrap'
  depends_on 'casarest'
  depends_on 'cfitsio'
  depends_on 'fftw'
  depends_on 'blitz'
  depends_on 'qdbm'
  depends_on 'pyqwt'
  depends_on 'numpy' => :python
  depends_on 'pyfits' => :python
  depends_on 'PIL' => :python
  # The following packages are strictly optional but by including them
  # it is easy to install the whole MeqTrees suite in one go
  # (and it allows testing the whole suite via Batchtest)
  depends_on 'purr'
  depends_on 'tigger'
  depends_on 'cattery'
  depends_on 'owlcat'
  depends_on 'makems'

  def patches
    # Added explicit template instantiation and corrected constness
    # Use correct version of strerror_r on the Mac
    # Fixed bug in thread map index
    # Add support for Blitz++ 0.10
    # Suppress compiler warning by using correct format specifier
    DATA
  end

  fails_with :clang do
    build 421
    cause <<-EOS.undent
      Throws 'allocation of incomplete type' error on DMI::NumArray
      EOS
  end

  def install
    # Hopefully this Python script will be included in MeqTrees repository in future
    if not File.exists? 'h2py.py'
      system 'curl -O http://hg.python.org/cpython/raw-file/1cfe0f50fd0c/Tools/scripts/h2py.py'
    end

    if build.include? 'enable-debug'
      build_type = 'debug'
    elsif build.include? 'without-symbols'
      build_type = 'release'
    else
      build_type = 'relwithdebinfo'
    end
    mkdir_p "build/#{build_type}"
    cd "build/#{build_type}"
    cmake_args = std_cmake_args
    cmake_args.delete '-DCMAKE_BUILD_TYPE=None'
    cmake_args << "-DCMAKE_BUILD_TYPE=#{build_type}"
    cmake_args << "-DCMAKE_SHARED_LINKER_FLAGS='-undefined dynamic_lookup'"
    system 'cmake', '../..', *cmake_args
    system "make"

    ohai "make install"
    # The debug symlink tree is the most complete - use as template for all build types
    cd "../../install/symlinked-debug/bin"
    Dir.foreach('.') do |item|
      next if ['.', '..', 'purr.py', 'trut'].include? item
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      bin.install item if File.exists? item
    end

    cd "../lib"
    Dir.foreach('.') do |item|
      next if not item.start_with? 'lib'
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      item.sub! '.so', '.dylib'
      lib.install item if File.exists? item
    end

    cd '../libexec/python/Timba'
    timba = "#{lib}/#{which_python}/site-packages/Timba"
    mkdir_p timba
    # Create DLFCN.py for our system
    quiet_system 'python ../../../../../h2py.py /usr/include/dlfcn.h'
    # Since Cattery while be installed in the usual path, we don't need to look for it
    inreplace '__init__.py', '"Cattery"', ''
    Dir.foreach('.') do |item|
      next if ['.', '..'].include? item
      # Preserve local links but dereference proper links
      item = if (File.symlink? item) and (File.readlink(item).start_with? '../')
             then File.readlink(item) else item end
      item.sub! '/debug/', "/#{build_type}/"
      if File.exists? item
        if item.end_with? '.dylib'
          # Move Python extensions to main library directory (as executables also link to them)
          # and symlink them back to module directory with desired .so extension
          lib.install item
          libname = File.basename(item, '.dylib')
          ln_s "#{lib}/#{libname}.dylib", "#{timba}/#{libname}.so"
        else
          cp_r item, timba+'/'
        end
      end
    end

    cd '../icons'
    mkdir_p "#{share}/meqtrees/icons"
    icons = 'treebrowser'
    icons = if File.symlink? icons then File.readlink(icons) else icons end
    cp_r icons, "#{share}/meqtrees/icons/" if File.exists? icons

    # Assemble debug symbol (*.dSYM) files if the build type requires it
    if build_type != 'release'
      cd "#{lib}"
      Dir.foreach('.') do |item|
        next if not item.end_with? '.dylib'
        safe_system 'dsymutil', item
      end
    end
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end

  def test
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test release`.
    system "false"
  end
end

__END__
diff --git a/DMI/src/DMI.h b/DMI/src/DMI.h
index 49e2e9b..8917bcf 100644
--- a/DMI/src/DMI.h
+++ b/DMI/src/DMI.h
@@ -110,6 +110,7 @@ namespace DMI
   // compile-time error reporting. This is borrowed from Alexandrescu
   template<int> struct CompileTimeError;
   template<> struct CompileTimeError<true> {};
+  template<> struct CompileTimeError<false> {};
 
 };
 
diff --git a/DMI/src/Packer.h b/DMI/src/Packer.h
index 2ef85ae..52372d5 100644
--- a/DMI/src/Packer.h
+++ b/DMI/src/Packer.h
@@ -525,8 +525,8 @@ template <class Map, class KeyPacker, class ValuePacker>
 void MapPacker<Map,KeyPacker,ValuePacker>::unpack (Map &mp, const void *block, size_t sz)
 {
   FailWhen(sz<sizeof(size_t),"corrupt block");
-  const size_t 
-    *hdr = static_cast<size_t*>(block),
+  size_t 
+    *hdr = const_cast<size_t*>(static_cast<const size_t*>(block)),
     n   = *(hdr++),
     sz0 = (1+ (KeyPacker::binary()?0:n) + (ValuePacker::binary()?0:n))*sizeof(size_t);
   FailWhen(sz<sz0,"corrupt block");
diff --git a/MEQ/src/FastParmTable.cc b/MEQ/src/FastParmTable.cc
index c0e53fc..7034607 100644
--- a/MEQ/src/FastParmTable.cc
+++ b/MEQ/src/FastParmTable.cc
@@ -164,7 +164,15 @@ void FastParmTable::throwErrno (const string &message)
 {
   int errno0 = errno;
   char errbuf[256];
+// This test was taken from Chromium's safe_strerror_posix.cc
+#if (defined(__GLIBC__) || defined(OS_NACL))
+  // Use the historical GNU-specific version of strerror_r found on e.g. Linux
   char *err = strerror_r(errno0,errbuf,sizeof(errbuf));
+#else
+  // Use the POSIX-compliant (XSI-compliant) version of strerror_r found on e.g. Darwin
+  int errno1 = strerror_r(errno0,errbuf,sizeof(errbuf));
+  char *err = errbuf;
+#endif
   Throw(Debug::ssprintf("%s: %s (errno=%d)",
         Debug::ssprintf(message.c_str(),table_name_.c_str()).c_str(),err,errno0));
 }
diff --git a/TimBase/src/Thread/Thread.cc b/TimBase/src/Thread/Thread.cc
index c90c7af..b673098 100644
--- a/TimBase/src/Thread/Thread.cc
+++ b/TimBase/src/Thread/Thread.cc
@@ -74,7 +74,7 @@ namespace LOFAR
       pthread_t id = 0;
       pthread_create(&id,attr,start,arg);
       // add to map
-      thread_map_[thread_list_.size()] = id;
+      thread_map_[id] = thread_list_.size();
       thread_list_.push_back(id);
       return id;
     }
diff --git a/MEQ/src/ComposedPolc.cc b/MEQ/src/ComposedPolc.cc
index 510b158..e895ef6 100644
--- a/MEQ/src/ComposedPolc.cc
+++ b/MEQ/src/ComposedPolc.cc
@@ -266,13 +266,13 @@ void ComposedPolc::validateContent (bool recursive)
 	  starti[axisi]=0;endi[axisi]=0;continue;
 	}
 	if (!polcdom.isDefined(axisi)){
-	  starti[axisi]=0;endi[axisi]=std::min(res_shape[axisi]-1,startgrid[axisi].size()-1);continue;
+	  starti[axisi]=0;endi[axisi]=std::min(res_shape[axisi]-1,static_cast<int>(startgrid[axisi].size())-1);continue;
 	}
-	int maxk=std::min(res_shape[axisi],startgrid[axisi].size());
+	int maxk=std::min(res_shape[axisi],static_cast<int>(startgrid[axisi].size()));
 	int k=0;
 	while(k<maxk  && centergrid[axisi](k)<polcdom.start(axisi)) k++;
 	starti[axisi] = k;
-	k=std::min(res_shape[axisi]-1,startgrid[axisi].size()-1);
+	k=std::min(res_shape[axisi]-1,static_cast<int>(startgrid[axisi].size())-1);
 	while(k>0 && (centergrid[axisi](k)>polcdom.end(axisi))) k--;
 	endi[axisi] = k;
 	cdebug(3)<<"axis : "<<axisi<<" begin : "<<starti[axisi]<<" end : "<<endi[axisi]<<endl;
diff --git a/MEQ/src/Polc.cc b/MEQ/src/Polc.cc
index 130f0e0..da0b1f8 100644
--- a/MEQ/src/Polc.cc
+++ b/MEQ/src/Polc.cc
@@ -224,7 +224,7 @@ void Polc::do_evaluate (VellSet &vs,const Cells &cells,
       grid[i] = ( grid[i] - getOffset(i) )*one_over_scale;
 
       cdebug(4)<<"calculating polc on grid "<<i<<" : "<<grid[i]<<endl;
-      res_shape[iaxis] = std::max(grid[i].size(),1);
+      res_shape[iaxis] = std::max(static_cast<int>(grid[i].size()),1);
     }
   }
   // now evaluate
diff --git a/MEQ/src/Spline.cc b/MEQ/src/Spline.cc
index beaccaa..ae001fc 100644
--- a/MEQ/src/Spline.cc
+++ b/MEQ/src/Spline.cc
@@ -195,7 +195,7 @@ void Spline::do_evaluate (VellSet &vs,const Cells &cells,
             " is not defined in Cells");
       grid[i].resize(cells.ncells(iaxis));
       grid[i] = cells.center(iaxis);
-      res_shape[iaxis] = std::max(grid[i].size(),1);
+      res_shape[iaxis] = std::max(static_cast<int>(grid[i].size()),1);
       total*=res_shape[iaxis];
     }
   }
diff --git a/TimBase/src/Lorrays-Blitz.h b/TimBase/src/Lorrays-Blitz.h
index d31b03d..11ca33f 100644
--- a/TimBase/src/Lorrays-Blitz.h
+++ b/TimBase/src/Lorrays-Blitz.h
@@ -258,16 +258,29 @@ class VariVector : public std::vector<int>
       VariVector (int n1,int n2,int n3,int n4,int n5) : std::vector<int>(5)
         { iterator iter = begin(); *iter++=n1; *iter++=n2; *iter++=n3; *iter++=n4; *iter++=n5; }
       
-      // construct from TinyVector
+      // construct from TinyVector<int,N>
       // (this assumes contiguity in TinyVector, which is probably pretty safe to assume)
       template<int N>
       VariVector( const blitz::TinyVector<int,N> &tvec )
           : std::vector<int>(tvec.data(),tvec.data() + N) {};
-      // convert to TinyVector
+      // convert to TinyVector<int,N>
       template<int N>
       operator blitz::TinyVector<int,N> () const
       { 
-        blitz::TinyVector<int,N> tvec(0);
+        int initial_value = 0;
+        blitz::TinyVector<int,N> tvec(initial_value);
+        for( int i = 0; i < std::min(N,(int)size()); i++ )
+          tvec[i] = (*this)[i];
+        return tvec;
+      }
+      // convert to TinyVector<long int,N>
+      // Since Blitz++ 0.10 the Blitz::Array stride has a different type (diffType) to the shape (int)
+      // and on at least some platforms diffType is long int
+      template<int N>
+      operator blitz::TinyVector<long int,N> () const
+      { 
+        long int initial_value = 0;
+        blitz::TinyVector<long int,N> tvec(initial_value);
         for( int i = 0; i < std::min(N,(int)size()); i++ )
           tvec[i] = (*this)[i];
         return tvec;
diff --git a/MeqNodes/src/TFSmearFactorApprox.cc b/MeqNodes/src/TFSmearFactorApprox.cc
index fb25bdf..4d10f54 100644
--- a/MeqNodes/src/TFSmearFactorApprox.cc
+++ b/MeqNodes/src/TFSmearFactorApprox.cc
@@ -54,22 +54,22 @@ using namespace VellsMath;
 // for teh normal stencils: used to have
 //    A = .5*central12(B,blitz::firstDim);
 BZ_DECLARE_STENCIL2(TimeDiff, A,B)
-    A = forward11(B,blitz::firstDim);
+    A = forward11_stencilop(B,blitz::firstDim);
 BZ_END_STENCIL
 BZ_DECLARE_STENCIL2(TimeDiff1,A,B)
-    A = forward11(B,blitz::firstDim);
+    A = forward11_stencilop(B,blitz::firstDim);
 BZ_END_STENCIL
 BZ_DECLARE_STENCIL2(TimeDiff2,A,B)
-    A = backward11(B,blitz::firstDim);
+    A = backward11_stencilop(B,blitz::firstDim);
 BZ_END_STENCIL
 BZ_DECLARE_STENCIL2(FreqDiff, A,B)
-    A = forward11(B,blitz::secondDim);
+    A = forward11_stencilop(B,blitz::secondDim);
 BZ_END_STENCIL
 BZ_DECLARE_STENCIL2(FreqDiff1,A,B)
-    A = forward11(B,blitz::secondDim);
+    A = forward11_stencilop(B,blitz::secondDim);
 BZ_END_STENCIL
 BZ_DECLARE_STENCIL2(FreqDiff2,A,B)
-    A = backward11(B,blitz::secondDim);
+    A = backward11_stencilop(B,blitz::secondDim);
 BZ_END_STENCIL
 
 
diff --git a/MeqNodes/src/CUDAPointSourceVisibility.cc b/MeqNodes/src/CUDAPointSourceVisibility.cc
index 3dec9d0..fe8a4f5 100644
--- a/MeqNodes/src/CUDAPointSourceVisibility.cc
+++ b/MeqNodes/src/CUDAPointSourceVisibility.cc
@@ -151,7 +151,7 @@ void CUDAPointSourceVisibility::checkTensorDims (int ichild,const LoShape &shape
   else
   {
     n = shape[0];
-    printf("child %i is dim %i\n", ichild, shape.size());
+    printf("child %i is dim %zu\n", ichild, shape.size());
     if( shape.size() == 2 )
     {
         printf("                 %i x %i\n", shape[0], shape[1]);
