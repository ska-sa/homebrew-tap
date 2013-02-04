require 'formula'

class Purr < Formula
  homepage 'http://www.astron.nl/meqwiki/Purr/Introduction'
  url 'https://svn.astron.nl/Purr/release/Purr/release-1.2.0'
  head 'https://svn.astron.nl/Purr/trunk/Purr'

  depends_on 'pyqt'
  depends_on 'pyfits' => :python

  def patches
    p = []
    # First look for icons in meqtrees share directory (fixed in HEAD)
    p << 'https://gist.github.com/raw/4705954/bdcfe30b6f63a4d634f33fcfa4334ea7760cd69d/patch1.diff' if not build.head?
    # Provide alternatives for Linux-only 'cp -u' and 'mv -u' (fixed in HEAD)
    p << 'https://gist.github.com/raw/4705954/95942b16e28c387b89ff64baf986b141c037d422/patch2.diff' if not build.head?
    # Escape spaces in paths sent to pychart to produce histograms (fixed in HEAD)
    p << 'https://gist.github.com/raw/4705954/fef3b6a3386a3b8c8ec512099fc14b2bcb680e47/patch3.diff' if not build.head?
    return p.empty? ? nil : p
  end

  def install
    bin.install 'Purr/purr.py', 'Purr/purr'
    mkdir_p "#{lib}/#{which_python}/site-packages"
    cp_r ['Purr', 'Kittens'], "#{lib}/#{which_python}/site-packages/"
    mkdir_p "#{share}/meqtrees"
    cp_r 'icons', "#{share}/meqtrees/"
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end

  def test
    if system 'python -c "import Purr"' then
      onoe 'Purr FAILED'
    else
      ohai 'Purr OK'
    end
  end
end
