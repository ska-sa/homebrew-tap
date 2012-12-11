require 'formula'

class Plplot < Formula
  url 'http://sourceforge.net/projects/plplot/files/plplot/5.9.9%20Source/plplot-5.9.9.tar.gz'
  homepage 'http://plplot.sourceforge.net'
  md5 '9f2c8536a58875d97ab6b29bbed67d26'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build
  depends_on 'pango'

  def install
    # system "mv ChangeLog.release ChangeLog" # this seems to be a packaging error in 5.9.9; make install looks for a ChangeLog file but there isn't one in the .tar.gz. This has been reported upstream -- see https://sourceforge.net/tracker/?func=detail&aid=3383853&group_id=2915&atid=102915
    system "mkdir plplot-build"
    Dir.chdir "plplot-build"
    system "cmake #{std_cmake_parameters} .."
    system "make"
    system "make install"
  end
end
