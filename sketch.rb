class Sketch < Formula
  desc 'A 3D scene description translator for producing line drawings in TeX'
  homepage 'http://sketch4latex.sourceforge.net/'
  url 'http://sketch4latex.sourceforge.net/sketch-0.3.7.tgz'
  sha256 '12962ad5fe5a0f7c9fc6d84bd4d09b879bbf604975c839405f1613be657ba804'

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
