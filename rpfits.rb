require 'formula'

class Rpfits < Formula
  url 'ftp://ftp.atnf.csiro.au/pub/software/rpfits/rpfits-2.23.tar.gz'
  homepage 'http://www.atnf.csiro.au/computing/software/rpfits.html'
  sha1 '16e4b14ea6cbdeedbc7f47adec3ff2b0aec621de'

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
