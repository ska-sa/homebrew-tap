require 'formula'

class Pyrap < Formula
  desc 'Python bindings for casacore, a library used in radio astronomy'
  homepage 'https://casacore.github.io/python-casacore/'

  stable do
    url 'https://pyrap.googlecode.com/files/pyrap-1.1.0.tar.bz2'
    sha256 "4ca7fa080d31de64680a78425f0ea02f36a1d8f019febf7e595234055e7e2d54"
    # Patch to disable explicit linking to system Python framework in order to support brew Python (and other non-system versions)
    patch do
      url 'https://gist.github.com/ludwigschwardt/5195760/raw/0dbf63fba7b4caed537c84eb26c42afc7db0ec23/patch5.diff'
      sha256 "8f8b78809b42bfe3e49f1be02be69f604c71e51af57ac9329c5901daa089b7c7"
    end
    # Fix C++11 issue (space between string and literal)
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/296b0ec87ceffc5a006138a0e9263cd97b553897/patch10.diff"
      sha256 "707744a2c115171a85ea882982a21775c569056f996fad6c11f2821dddbaba84"
    end
    # Enable C++11 both for libpyrap and the python extensions for clang
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/c8fc9ce1a65d7e198a2013d1a828fae738fa147e/patch11.diff"
      sha256 "a89e080babe6e63222d0898f6c75276530afbd9efc7767dfebf037b4e903d393"
    end
    # CASA components library has been dropped from 2.0.0
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/11b648371df7d17f1264ef67d7b782eaa31bef54/patch12.diff"
      sha256 "5b1291336822107f007db99ea4804e32cb7e71ccc68758134ac69453f8457bfe"
    end
  end

  head do
    url 'https://github.com/casacore/python-casacore.git'
    # Patch to support compilation on Mac OS 10.7+ (Lion and up) by ignoring sysroot
    patch do
      url 'https://gist.github.com/ludwigschwardt/5195760/raw/c0981d0c27b3086cb7378cf4442b2754abc8a42d/patch2.diff'
      sha256 '2d5f315ffdbbcab7ae428e7418a22fe89b8067e09e5ea3cee250fa28b253a1c9'
    end
    # Patch to ignore fortran to c library (aka libgfortran)
    patch do
      url 'https://gist.github.com/ludwigschwardt/5195760/raw/5bdd5e6ab42e9551750128c441a775dffaa3feea/patch4.diff'
      sha256 '8bb39b4d9436818a6b579a9d536b849d4417b553dbe686c6b455e54d52a88c89'
    end
    # Patch to disable explicit linking to system Python framework in order to support brew Python (and other non-system versions)
    patch do
      url 'https://gist.github.com/ludwigschwardt/5195760/raw/a270c600a5870523192a791c6a4459bbddc293b3/patch6.diff'
      sha256 'c204c14f0864d3cc7668354b0129c6f70b9ad6630543b688a75a499eca85d6af'
    end
    # Fix C++11 issue (space between string and literal)
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/e13d6971f7647591572a9a0faf7e393f032cb488/patch7.diff"
      sha256 '6ea089c5d7ba59b6f2e535929304d14ba26d12ffcc205c3c5a51c3b849d15ec3'
    end
    # Enable C++11 both for libpyrap and the python extensions for clang
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/3e32d83f58a4abdd15d7530583a659feaa39c15a/patch8.diff"
      sha256 "e7781da938d509809e62f40dace1361ad2b6de43f452c51f5e259932bc504936"
    end
    # CASA components library has been dropped from 2.0.0
    patch do
      url "https://gist.github.com/ludwigschwardt/5195760/raw/ecfe7c62cab531599b096e6e9db962468735d203/patch9.diff"
      sha256 "2f0111c117b5c715843e5559dba8ed4779123ce7550d47d3e8c81469e126fa31"
    end
  end

  depends_on 'scons' => :build
  depends_on 'boost-python'
  depends_on 'casacore'
  depends_on 'python@2'
  depends_on 'numpy'

  # Patch to support compilation on Mac OS 10.7+ (Lion and up) by ignoring sysroot
  patch do
    url 'https://gist.github.com/ludwigschwardt/5195760/raw/da9264e50c244b84cd92e180b207e13928f7ff93/patch1.diff'
    sha256 'aa4ccbf03fce7a136bbeda47c625fe0e61d119a3aa1ef3315ce86ae2a0aa8fa7'
  end
  # Patch to ignore fortran to c library (aka libgfortran)
  patch do
    url 'https://gist.github.com/ludwigschwardt/5195760/raw/0bda200fb5c8f743c488077e94195c786ecb2486/patch3.diff'
    sha256 '3ffb0226a509633eec1adcdae4f2e60c5013b6524a02ba4b506e0f6c784154d0'
  end

  def install
    if build.head?
      build_cmd = 'batchbuild-trunk.py'
    else
      build_cmd = 'batchbuild.py'
    end
    # Obtain information on Python installation
    python_xy = "python" + %x(python -c 'import sys;print(sys.version[:3])').chomp
    python_site_packages = lib + "#{python_xy}/site-packages"
    system "python", build_cmd,
           "--boost-root=#{HOMEBREW_PREFIX}", "--boost-lib=boost_python-mt",
           "--enable-hdf5", "--prefix=#{prefix}",
           "--python-prefix=#{python_site_packages}",
           "--universal=x86_64"
    # Get rid of horrible eggs as they trample on other packages via site.py and easy-install.pth
    cd "#{python_site_packages}"
    rm_f ['easy-install.pth', 'site.py', 'site.pyc']
    mkdir 'pyrap'
    touch 'pyrap/__init__.py'
    Dir['pyrap.*.egg'].each do |egg|
      Dir.foreach("#{egg}/pyrap") do |item|
        next if ['.', '..', '__init__.py', '__init__.pyc'].include? item
        mv "#{egg}/pyrap/#{item}", 'pyrap/'
      end
      rm_rf egg
    end
  end
end
