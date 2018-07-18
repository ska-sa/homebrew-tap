class SofaC < Formula
  desc "Standards of Fundamental Astronomy routines (ANSI C version)"
  homepage "http://www.iausofa.org/"
  url "http://www.iausofa.org/2018_0130_C/sofa_c-20180130.tar.gz"
  sha256 "de09807198c977e1c58ea1d0c79c40bdafef84f2072eab586a7ac246334796db"

  def install
    cd "#{version}/c/src"
    system "make", "install", "INSTALL_DIR=#{prefix}"
  end
end
