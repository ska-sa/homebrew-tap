require 'formula'

class Libwww < Formula
  homepage 'http://www.w3.org/Library/'
  url 'http://www.w3.org/Library/Distribution/w3c-libwww-5.4.0.tgz'
  sha1 '2394cb4e0dc4e2313a9a0ddbf508e4b726e9af63'

  depends_on 'pkg-config' => :build

  def patches
    # MacPorts patches
    { :p0 => ['https://trac.macports.org/export/100399/trunk/dports/www/libwww/files/patch-configure.diff',
              'https://trac.macports.org/export/100399/trunk/dports/www/libwww/files/libwww-config.in.diff']
    }
  end

  def install
    ENV.deparallelize
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make install"
  end
end
