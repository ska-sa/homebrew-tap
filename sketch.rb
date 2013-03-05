require 'formula'

class Sketch < Formula
  homepage 'http://www.frontiernet.net/~eugene.ressler/'
  url 'http://www.frontiernet.net/~eugene.ressler/sketch-0.3.7.tgz'
  sha1 'ac12a4efa10e4f32f6bd736485e9a9413143e730'

  # Building the documentation requires access to GhostScript
  env :userpaths

  depends_on :tex
  depends_on 'epstool' => :build

  def install
    system "make docs"
    bin.install "sketch"
    doc.install "Doc/sketch.pdf"
  end
end
