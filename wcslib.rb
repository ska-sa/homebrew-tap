require 'formula'

class Wcslib < Formula
  url 'ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-4.16.tar.bz2'
  homepage 'http://www.atnf.csiro.au/people/mcalabre/WCS/'
  sha1 'd321ee3c82ecb14e447006ed475f3f0217aa589f'

  option 'without-tests', 'Do not install test suite'

  depends_on 'cfitsio'
  depends_on 'pgplot'

  def install
    ENV.fortran
    ENV.j1
    system "./configure", "--prefix=#{prefix}",
    "--with-cfitsiolib=#{HOMEBREW_PREFIX}/lib", "--with-cfitsioinc=#{HOMEBREW_PREFIX}/include",
    "--with-pgplotlib=#{HOMEBREW_PREFIX}/lib", "--with-pgplotinc=#{HOMEBREW_PREFIX}/include"
    system "make all"
    chmod 0644, 'Fortran/test/twcstab.f'
    inreplace 'Fortran/test/twcstab.f', '../C/wcstab.fits', 'wcstab.fits'
    system "make tests" if not build.include? 'without-tests'
    system "make install"

    # Install tests by default - preserve basic directory structure as in source tree
    if not build.include? 'without-tests'
      mkdir_p ["#{libexec}/tests/C/output", "#{libexec}/tests/Fortran/output"]
      Dir.foreach('C') do |testname|
        if File.file? "C/test/#{testname}.c"
          cp "C/#{testname}", "#{libexec}/tests/C/"
        end
      end
      cp_r Dir["C/test/*.out"], "#{libexec}/tests/C/output/"
      cp ['C/test/units_test','C/test/wcstab.keyrec'], "#{libexec}/tests/"
      Dir.foreach('Fortran') do |testname|
        if File.file? "Fortran/test/#{testname}.f"
          cp "Fortran/#{testname}", "#{libexec}/tests/Fortran/"
        end
      end
      cp_r Dir["Fortran/test/*.out"], "#{libexec}/tests/Fortran/output/"
      cp 'pgsbox/pgtest', "#{libexec}/tests/" if File.file? 'pgsbox/pgtest'
      cp 'pgsbox/cpgtest', "#{libexec}/tests/" if File.file? 'pgsbox/cpgtest'
      cd 'C'
      quiet_system 'make tofits'
      Dir.foreach('test') do |keyrec|
        next if not keyrec.end_with? '.keyrec'
        fitsname = File.basename(keyrec, '.keyrec')
        safe_system "./tofits < test/#{keyrec} > #{fitsname}.fits"
        cp "#{fitsname}.fits", "#{libexec}/tests/"
      end
    end
  end

  def test
    if not File.directory? "#{libexec}/tests"
      opoo "No tests were installed due to --without-tests option"
    else
      mktemp do
        cp_r Dir["#{libexec}/tests/*"], '.'
        ln_s '.', 'test'
        ['C', 'Fortran'].each do |testdir|
          Dir.foreach(testdir) do |testname|
            next if ['.', '..', 'output', 'tsphdpa', 'twcshdr'].include? testname
            command = "yes | #{testdir}/#{testname}"
            if testname.end_with? 'tunits'
              command += '  < units_test'
            elsif testname.end_with? 'tcel2'
              command = "echo N | " + command
            end
            safe_system "#{command} > #{testname}.out 2>&1"
            if File.file? "#{testdir}/output/#{testname}.out"
              safe_system "sed -e 's/0x[0-9a-f][0-9a-f][0-9a-f]*/0x<address>/g' #{testname}.out > generic.out"
              success = cmp 'generic.out', "#{testdir}/output/#{testname}.out"
            elsif File.open("#{testname}.out") {|f| f.readline.start_with? 'Testing closure'}
              success = File.open("#{testname}.out") {|f| f.grep('/PASS:/')}
            else
              success = true
            end
            if success
              ohai "#{testdir}/#{testname} PASS"
            else
              onoe "#{testdir}/#{testname} FAIL"
            end
          end
        end
        if File.file? 'pgtest'
          quiet_system 'yes | ./pgtest'
          ohai "pgtest PASS"
        end
        if File.file? 'cpgtest'
          quiet_system 'yes | ./cpgtest'
          ohai "cpgtest PASS"
        end
      end
    end
  end
end
