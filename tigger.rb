require 'formula'

class Tigger < Formula
  desc 'A FITS viewer and sky model management tool (part of MeqTrees)'
  homepage 'https://github.com/ska-sa/meqtrees/wiki/Tigger'
  url 'https://svn.astron.nl/Tigger/release/Tigger/release-1.2.2'
  head 'https://svn.astron.nl/Tigger/trunk/Tigger'

  depends_on 'python@2'
  depends_on 'numpy'
  depends_on 'scipy'
  depends_on 'purr'
  # Missing dependencies: pyfits, pyqwt, astLib

  if not build.head?
    # Ignore setAllowX11ColorNames attribute on non-X11 Mac platform (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4565060/3a11913eff383b188a7dc887d560140b2b2b3500/patch1.diff'
    end
    # Fix imports to be absolute (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4565060/b42096bf9569b60a11f99a7432826e6235be5c4b/patch2.diff'
    end
    # Nuke matplotlib differently (dummy_module clashes with pkg_resources) (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4565060/95dc15b776855ed4273c79d18e1c99177ea8b41a/patch4.diff'
    end
  end
#    p << 'https://gist.github.com/raw/4565060/2bc9f42182180401adb52b8be065d1c70d39fe37/patch3.diff' if build.head?

  def install
    # Obtain information on Python installation
    python_xy = "python" + %x(python -c 'import sys;print(sys.version[:3])').chomp
    python_site_packages = lib + "#{python_xy}/site-packages"
    tigger = "#{python_site_packages}/Tigger"
    mkdir_p ["#{tigger}", "#{share}/doc", "#{share}/meqtrees"]
    cp_r '.', "#{tigger}/"
    rm_rf ["#{tigger}/bin", "#{tigger}/doc", "#{tigger}/icons"]
    cp_r 'bin', "#{bin}"
    rm_f "#{bin}/tigger"
    ln_s "#{tigger}/tigger", "#{bin}/tigger"
    cp_r 'doc', "#{share}/doc/tigger"
    cp_r 'icons', "#{share}/meqtrees/"
  end

  test do
    if system "python -c 'import Tigger'" then
      onoe 'Tigger FAILED'
    else
      ohai 'Tigger OK'
    end
  end
end
