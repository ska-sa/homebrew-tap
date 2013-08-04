require 'formula'

class Cattery < Formula
  homepage 'http://www.astron.nl/meqwiki/MeqTrees'
  url 'https://svn.astron.nl/MeqTrees/release/Cattery/release-1.2.0'
  head 'https://svn.astron.nl/MeqTrees/trunk/Cattery'

  depends_on :python

  def install
    mkdir_p "#{python.site_packages}"
    rm_f 'Meow/LSM0'
    cp_r 'LSM', 'Meow/LSM0'
    cp_r ['Calico', 'LSM', 'Lions', 'Meow', 'Siamese', 'qt.py'],
         "#{python.site_packages}/"
    if build.head?
      cp_r 'Scripter', "#{python.site_packages}/"
    end
    mkdir_p "#{share}/meqtrees"
    cp_r 'test', "#{share}/meqtrees/"
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{python.global_site_packages}:$PYTHONPATH
    EOS
  end
end
