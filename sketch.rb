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
    mkdir_p "#{share}/sketch/examples"
    cp_r Dir['Data/*'], "#{share}/sketch/examples/"
  end

  def test
    mktemp do
      cp_r Dir["#{share}/sketch/examples/*.sk"], '.'
      Dir['*.sk'].each do |name|
        # Contains a pspicture baseline that causes unhappiness
        next if name == 'buggy.sk'
        quiet_system "sketch -T #{name} > #{name}.tex"
        quiet_system 'latex', "#{name}.tex"
        quiet_system 'dvips', "#{name}.dvi"
        quiet_system 'ps2pdf', "#{name}.ps"
#        quiet_system 'open', "#{name}.pdf"
        ohai "#{name} OK"
      end
    end
  end
end
