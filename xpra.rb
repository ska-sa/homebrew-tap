require 'formula'

class Xpra < Formula
  homepage 'http://xpra.org'
  url 'http://winswitch.org/src/xpra-0.10.9.tar.bz2'
  sha1 '1fe8113242143d51f492502e1d0c7441c34cbf23'

  # We want pkg-config
  env :userpaths

  depends_on :python
  depends_on :x11
  depends_on 'pygtk'
  depends_on 'ffmpeg'
  depends_on 'libvpx'
  depends_on 'webp'
  depends_on 'Cython' => :python

  def install
    python do
      system python, "setup.py", "install", "--prefix=#{prefix}"
    end
  end

  def caveats
    python.standard_caveats if python
  end
end
