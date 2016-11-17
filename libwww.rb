require 'formula'

class Libwww < Formula
  homepage 'http://www.w3.org/Library/'
  url 'http://www.w3.org/Library/Distribution/w3c-libwww-5.4.0.tgz'
  sha256 '64841cd99a41c84679cfbc777ebfbb78bdc2a499f7f6866ccf5cead391c867ef'

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
