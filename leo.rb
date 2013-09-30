require 'formula'

class Leo < Formula
  homepage 'http://leoeditor.com/'
  url 'http://sourceforge.net/projects/leo/files/Leo/4.10%20final/Leo-4.10-final.zip'
  sha1 '1988c54d34d2233eda7ba2faa02066ff02575fec'
  head 'https://code.launchpad.net/leo-editor', :using => :bzr
  devel do
    url 'http://sourceforge.net/projects/leo/files/Leo/4.11-a2/Leo-4.11-a2.zip'
    sha1 '435c023df4d7b378ba10594a4b46ca83e82fc6b2'
  end

  depends_on :python
  depends_on 'pyqt'
  depends_on 'enchant' => :recommended

  def install
    python.site_packages.install 'leo'
    bin.install ['launchLeo.py', 'profileLeo.py']
    ln_s "#{bin}/launchLeo.py", "#{bin}/leo"
  end

  def caveats
    python.standard_caveats if python
  end

  test do
    if system "#{python} -c 'import leo'" then
      onoe 'Leo FAILED'
    else
      ohai 'Leo OK'
    end
  end
end
