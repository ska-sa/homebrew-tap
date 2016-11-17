require 'formula'

class Leo < Formula
  homepage 'http://leoeditor.com/'
  url 'http://sourceforge.net/projects/leo/files/Leo/4.10%20final/Leo-4.10-final.zip'
  sha256 '3c27d28e8127094aee9a9dba3d4b5093275e5f35af1b2d3ea1e8b76e5a9f7c7b'
  head 'https://code.launchpad.net/leo-editor', :using => :bzr

  depends_on 'pyqt'
  depends_on 'enchant' => :recommended

  def install
    # Obtain information on Python installation
    python_xy = "python" + %x(python -c 'import sys;print(sys.version[:3])').chomp
    python_site_packages = lib + "#{python_xy}/site-packages"
    python_site_packages.install 'leo'
    bin.install ['launchLeo.py', 'profileLeo.py']
    ln_s "#{bin}/launchLeo.py", "#{bin}/leo"
  end

  test do
    if system "python -c 'import leo'" then
      onoe 'Leo FAILED'
    else
      ohai 'Leo OK'
    end
  end
end
