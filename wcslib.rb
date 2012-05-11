require 'formula'

class Wcslib < Formula
  url 'ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-4.13.4.tar.bz2'
  homepage 'http://www.atnf.csiro.au/people/mcalabre/WCS/'
  md5 '94a24c7abd7d8edc514ed10896cbf4f0'

  depends_on 'cfitsio'
  depends_on 'pgplot'

  def install
    ENV.fortran
    ENV.j1
    system "./configure", "--prefix=#{prefix}",
    "--with-cfitsiolib=#{HOMEBREW_PREFIX}/lib", "--with-cfitsioinc=#{HOMEBREW_PREFIX}/include",
    "--with-pgplotlib=#{HOMEBREW_PREFIX}/lib", "--with-pgplotinc=#{HOMEBREW_PREFIX}/include"
    system "make all"
    system "make install"
  end
end
