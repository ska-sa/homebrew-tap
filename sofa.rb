class Sofa < Formula
  desc "Standards of Fundamental Astronomy routines (Fortran 77 version)"
  homepage "http://www.iausofa.org/"
  url "http://www.iausofa.org/2018_0130_F/sofa_f-20180130.tar.gz"
  sha256 "175cb39a6b65bd1e5506ed2ea57220e81defab9b4e766e215f6f245458e93d90"

  depends_on "gcc"

  def install
    cd "#{version}/f77/src"
    system "make", "install", "INSTALL_DIR=#{prefix}"
  end
end
