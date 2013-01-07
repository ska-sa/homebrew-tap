require 'formula'

class Purr < Formula
  homepage 'http://www.astron.nl/meqwiki/Purr/Introduction'
  head 'https://svn.astron.nl/Purr/trunk/Purr'

  def install 
    mkdir_p "#{lib}/#{which_python}/site-packages"
    cp_r '.', "#{lib}/#{which_python}/site-packages/"
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
