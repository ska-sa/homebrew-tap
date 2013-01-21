require 'formula'

class Libmodbus2 < Formula
  url 'http://github.com/downloads/stephane/libmodbus/libmodbus-2.0.4.tar.gz'
  homepage 'http://libmodbus.org'
  sha1 'f9bed0fac60d8409865a9eddd88b2dc109d407cb'

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
