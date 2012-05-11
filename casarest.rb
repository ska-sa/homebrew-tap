require 'formula'

class Casarest < Formula
  url 'svn://lofar9.astron.nl/var/svn/repos/trunk/casarest'
  version '1.0.0'
  homepage 'http://www.astron.nl/meqwiki/LinkingWithCasaCore'
  md5 ''

  depends_on 'casacore'
  depends_on 'cmake'
  depends_on 'boost'
  depends_on 'readline'
  depends_on 'wcslib'
  depends_on 'hdf5'

  fails_with :clang do
    build 318
    cause <<-EOS.undent
      Code does not follow C++ standard strictly but does whatever GCC allows
      EOS
  end

  def patches
    # Fixes disallowed size_t vs int* comparison, which used to be specially
    # included for Darwin systems, but does not seem relevant anymore.
    DATA
  end

  def install
    ENV.fortran
    Dir.mkdir 'build'
    FileUtils.chdir('build', :verbose => false)
    system "cmake .. -DCASACORE_ROOT_DIR=#{HOMEBREW_PREFIX} -DHDF5_ROOT_DIR=#{HOMEBREW_PREFIX} -DCMAKE_INSTALL_PREFIX=#{prefix}"
    system "make install"
    system "mkdir -p #{prefix}/share"
    system "mv ../measures_data #{prefix}/share/measures_data"
  end

  def test
  end
end

__END__
diff --git a/msvis/MSVis/AsynchronousTools.cc b/msvis/MSVis/AsynchronousTools.cc
index 81ad733..c442f0d 100644
--- a/msvis/MSVis/AsynchronousTools.cc
+++ b/msvis/MSVis/AsynchronousTools.cc
@@ -508,13 +508,8 @@ Semaphore::Semaphore (int initialValue)
 
         name_p = utilj::format ("/CasaAsync_%03d", i);
         impl_p->semaphore_p = sem_open (name_p.c_str(), O_CREAT | O_EXCL, 0700, initialValue);//new sem_t;
-#ifdef __APPLE__
-        code = (size_t(impl_p->semaphore_p) == SEM_FAILED) ? errno : 0;
-    } while (size_t(impl_p->semaphore_p) == SEM_FAILED && code == EEXIST);
-#else
         code = (impl_p->semaphore_p == SEM_FAILED) ? errno : 0;
     } while (impl_p->semaphore_p == SEM_FAILED && code == EEXIST);
-#endif
 
     ThrowIfError (code, "Semaphore::open: name='" + name_p + "'");
 }
