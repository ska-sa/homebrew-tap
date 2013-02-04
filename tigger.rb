require 'formula'

class Tigger < Formula
  homepage 'http://www.astron.nl/meqwiki/Tigger'
  url 'https://svn.astron.nl/Tigger/release/Tigger/release-1.2.2'
  head 'https://svn.astron.nl/Tigger/trunk/Tigger'

  depends_on 'pyqwt'
  depends_on 'purr'
  depends_on 'pyfits' => :python
  depends_on 'numpy' => :python
  depends_on 'scipy' => :python
  depends_on 'astLib' => :python

  def patches
    p = []
    # Ignore setAllowX11ColorNames attribute on non-X11 Mac platform (fixed in HEAD)
    p << 'https://gist.github.com/raw/4565060/3a11913eff383b188a7dc887d560140b2b2b3500/patch1.diff' if not build.head?
    # Fix imports to be absolute (fixed in HEAD)
    p << 'https://gist.github.com/raw/4565060/b42096bf9569b60a11f99a7432826e6235be5c4b/patch2.diff' if not build.head?
#    p << 'https://gist.github.com/raw/4565060/2bc9f42182180401adb52b8be065d1c70d39fe37/patch3.diff' if build.head?
    # Nuke matplotlib differently (dummy_module clashes with pkg_resources) (fixed in HEAD)
    p << 'https://gist.github.com/raw/4565060/95dc15b776855ed4273c79d18e1c99177ea8b41a/patch4.diff' if not build.head?
    return p.empty? ? nil : p
  end

  def install
    tigger = "#{lib}/#{which_python}/site-packages/Tigger"
    mkdir_p ["#{tigger}", "#{share}/doc", "#{share}/meqtrees"]
    cp_r '.', "#{tigger}/"
    rm_rf ["#{tigger}/bin", "#{tigger}/doc", "#{tigger}/icons"]
    cp_r 'bin', "#{bin}"
    rm_f "#{bin}/tigger"
    ln_s "#{tigger}/tigger", "#{bin}/tigger"
    cp_r 'doc', "#{share}/doc/tigger"
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
    if system 'python -c "import Tigger"' then
      onoe 'Tigger FAILED'
    else
      ohai 'Tigger OK'
    end
  end
end
