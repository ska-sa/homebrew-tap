require 'formula'

class Rpfits < Formula
  url 'ftp://ftp.atnf.csiro.au/pub/software/rpfits/rpfits-2.23.tar.gz'
  homepage 'http://www.atnf.csiro.au/computing/software/rpfits.html'
  md5 '197407a6b463e8d8f40040075a3983a3'

  def install
    ENV.j1
    ENV.fortran
    ENV['RPARCH'] = "darwin"
    system "make -f GNUmakefile"
    lib.install ['librpfits.a']
    bin.install ['rpfex','rpfhdr']
    include.install ['code/RPFITS.h']
  end
end
