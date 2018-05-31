require 'formula'

class Sketch < Formula
  desc 'A 3D scene description translator for producing line drawings in TeX'
  homepage 'http://www.frontiernet.net/~eugene.ressler/'
  url 'http://www.frontiernet.net/~eugene.ressler/sketch-0.3.7.tgz'
  sha256 '09ddd286cba6ab4d4cba0ded986231f7b0f9cff4cb0c35d121ec1d65af4a14fe'

  # Building the documentation requires access to GhostScript
  env :userpaths

  depends_on 'epstool' => :build

  def install
    system "make docs"
    bin.install "sketch"
    doc.install "Doc/sketch.pdf"
    mkdir_p "#{share}/sketch/examples"
    cp_r Dir['Data/*'], "#{share}/sketch/examples/"
  end

  test do
    mktemp do
      cp_r Dir["#{share}/sketch/examples/*.sk"], '.'
      Dir['*.sk'].each do |name|
        # Contains a pspicture baseline that causes unhappiness
        next if name == 'buggy.sk'
        quiet_system "#{bin}/sketch -T #{name} > #{name}.tex"
        quiet_system '#{bin}/latex', "#{name}.tex"
        quiet_system '#{bin}/dvips', "#{name}.dvi"
        quiet_system '#{bin}/ps2pdf', "#{name}.ps"
#        quiet_system 'open', "#{name}.pdf"
        ohai "#{name} OK"
      end
    end
  end
end
