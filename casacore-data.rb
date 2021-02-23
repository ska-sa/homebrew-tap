class ZtarDownloadStrategy < CurlDownloadStrategy
  def stage(&block)
    UnpackStrategy::Tar.new(cached_location).extract(basename: basename, verbose: verbose?)
    chdir(&block)
  end
end

class CasacoreData < Formula
  desc "Ephemerides and geodetic data for casacore measures (via Astron)"
  homepage "https://github.com/casacore/casacore"
  head "ftp://ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar", :using => ZtarDownloadStrategy

  deprecated_option "use-casapy" => "with-casapy"
  option "with-casapy", "Use Mac CASA.App (aka casapy) data directory if found"

  APP_DIR = Pathname.new "/Applications"
  CASAPY_APP_NAME = "CASA.app"
  CASAPY_APP_DIR = APP_DIR / CASAPY_APP_NAME
  CASAPY_DATA = CASAPY_APP_DIR / "Contents/data"

  def install
    if build.with? "casapy"
      if !Dir.exists? CASAPY_APP_DIR
        odie "--with-casapy was specified, but #{CASAPY_APP_NAME} was not found in #{APP_DIR}"
      elsif !Dir.exists? CASAPY_DATA
        odie "--with-casapy was specified, but data directory not found at #{CASAPY_DATA}"
      end
      prefix.install_symlink CASAPY_DATA
    else
      (prefix / CASAPY_DATA.basename).install Dir["*"]
    end
  end

  test do
    Dir.exists? (prefix / CASAPY_DATA.basename / "ephemerides")
    Dir.exists? (prefix / CASAPY_DATA.basename / "geodetic")
  end

  def caveats
    data_dir = prefix / CASAPY_DATA.basename
    if File.symlink? data_dir
      "Linked to CASA data directory (#{CASAPY_DATA}) from #{data_dir}"
    else
      "Installed latest Astron WSRT_Measures tarball to #{data_dir}"
    end
  end
end
