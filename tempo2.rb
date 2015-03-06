class Tempo2 < Formula
  homepage "http://www.atnf.csiro.au/research/pulsar/tempo2/"
  url "https://downloads.sourceforge.net/tempo2/tempo2-2013.9.1.tar.gz"
  sha256 "79dede8fcb4deb66789d6acffa775cfc27ed33412eb795c93aad4dbe054cd933"

  depends_on :x11
  depends_on :fortran

  depends_on "pgplot"
  depends_on "fftw"
  depends_on "cfitsio"
  depends_on "gsl"

  def install
    share.install "T2runtime"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "--with-tempo2-plug-dir=#{share}/T2runtime/plugins"
    system "make", "install"
    system "make", "plugins-install"
  end

  def caveats
    s = <<-EOS.undent
      Please set the TEMPO2 environment variable to:

      export TEMPO2=#{share}/T2runtime
    EOS
    s
  end

  test do
    system "TEMPO2=#{share}/T2runtime", bin/"tempo2", "-h", "||", "[", "$?", "==", "1", "]"
  end
end
