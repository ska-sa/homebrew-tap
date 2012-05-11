require 'formula'

class Libmodbus2 < Formula
  url 'http://github.com/downloads/stephane/libmodbus/libmodbus-2.0.4.tar.gz'
  homepage 'http://libmodbus.org'
  md5 '6b3aa500ab441a953eeb73a8c58cdf76'

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
