require 'formula'

class Rpfits < Formula
  desc 'Library to access ATCA visibility data in RPFITS format'
  homepage 'http://www.atnf.csiro.au/computing/software/rpfits.html'
  url 'ftp://ftp.atnf.csiro.au/pub/software/rpfits/rpfits-2.23.tar.gz'
  sha256 '7fbed9951b16146ee8d02b09f447adb1706e812c33a1026e004b7feb63f221a0'

  depends_on "gcc"

  def install
    ENV.deparallelize
    ENV['RPARCH'] = "darwin"
    system "make -f GNUmakefile"
    lib.install ['librpfits.a']
    bin.install ['rpfex','rpfhdr']
    include.install ['code/RPFITS.h']
  end
end
