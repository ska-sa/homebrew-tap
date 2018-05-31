require 'formula'

class Purr < Formula
  desc 'A GUI tool for auto-generating descriptive data processing logs'
  homepage 'https://github.com/ska-sa/meqtrees/wiki/Purr-Introduction'
  url 'https://svn.astron.nl/Purr/release/Purr/release-1.2.0'
  head 'https://github.com/ska-sa/purr.git'

  depends_on 'python@2'
  depends_on 'pyqt'
  # Missing dependencies: pyfits

  if not build.head?
    # First look for icons in meqtrees share directory (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4705954/bdcfe30b6f63a4d634f33fcfa4334ea7760cd69d/patch1.diff'
    end
    # Provide alternatives for Linux-only 'cp -u' and 'mv -u' (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4705954/95942b16e28c387b89ff64baf986b141c037d422/patch2.diff'
    end
    # Escape spaces in paths sent to pychart to produce histograms (fixed in HEAD)
    patch do
      url 'https://gist.github.com/raw/4705954/fef3b6a3386a3b8c8ec512099fc14b2bcb680e47/patch3.diff'
    end
  end

  def install
    # Obtain information on Python installation
    python_xy = "python" + %x(python -c 'import sys;print(sys.version[:3])').chomp
    python_site_packages = lib + "#{python_xy}/site-packages"
    bin.install 'Purr/purr.py', 'Purr/purr'
    mkdir_p "#{python_site_packages}"
    cp_r ['Purr', 'Kittens'], "#{python_site_packages}/"
    mkdir_p "#{share}/meqtrees"
    cp_r 'icons', "#{share}/meqtrees/"
  end

  test do
    if system "python -c 'import Purr'" then
      onoe 'Purr FAILED'
    else
      ohai 'Purr OK'
    end
  end
end
