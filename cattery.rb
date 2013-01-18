require 'formula'

class Cattery < Formula
  homepage 'http://www.astron.nl/meqwiki/MeqTrees'
  url 'https://svn.astron.nl/MeqTrees/release/Cattery/release-1.2.0'
  head 'https://svn.astron.nl/MeqTrees/trunk/Cattery'

  def install
    mkdir_p "#{lib}/#{which_python}/site-packages"
    rm_f 'Meow/LSM0'
    cp_r 'LSM', 'Meow/LSM0'
    cp_r ['Calico', 'LSM', 'Lions', 'Meow', 'Siamese', 'qt.py'],
         "#{lib}/#{which_python}/site-packages/"
    if build.head?
      cp_r 'Scripter', "#{lib}/#{which_python}/site-packages/"
    end
    mkdir_p "#{share}/meqtrees"
    cp_r 'test', "#{share}/meqtrees/"
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
