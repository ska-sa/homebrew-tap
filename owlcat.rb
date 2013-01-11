require 'formula'

class Owlcat < Formula
  homepage 'http://www.astron.nl/meqwiki-data/users/oms/Owlcat-plotms-tutorial.purrlog/'
# Waiting for next release after 1.2.0 to be supported on Mac
#  url 'https://svn.astron.nl/Owlcat/release/Owlcat/release-1.2.0'
  head 'https://svn.astron.nl/Owlcat/trunk/Owlcat'

  depends_on 'pyfits' => :python
  depends_on 'numpy' => :python
  depends_on 'matplotlib' => :python
  depends_on 'casacore'
  depends_on 'pyrap'
  depends_on 'cattery'

  def install
    inreplace 'owlcat.sh', 'dir=`dirname $(readlink -f $0)`', "dir='#{libexec}'"
    bin.install 'owlcat.sh'
    mv "#{bin}/owlcat.sh", "#{bin}/owlcat"
    mkdir_p "#{lib}/#{which_python}/site-packages"
    # Since Cattery while be installed in the usual path, we don't need to look for it
    inreplace 'Owlcat/__init__.py', '"Cattery"', ''
    cp_r 'Owlcat', "#{lib}/#{which_python}/site-packages/"
    libexec.install Dir['*.py'], Dir['*.sh'], 'commands.list'
    doc.install 'tutorial/Owlcat-plotms-tutorial.purrlog'
    doc.install 'README', 'imager.conf.example', 'owlcat-logo.jpg'
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end
end
