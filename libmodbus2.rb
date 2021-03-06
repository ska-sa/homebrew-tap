class Libmodbus2 < Formula
  desc 'A library to send/receive data according to the Modbus protocol'
  homepage 'http://libmodbus.org'
  url 'https://github.com/downloads/stephane/libmodbus/libmodbus-2.0.4.tar.gz'
  sha256 '408b314cbfd2bc494a8c4059db29a5d514d8a102a73519eda44517492aeffaf0'

  def install
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end
end
