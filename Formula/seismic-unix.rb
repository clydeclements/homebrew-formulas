class SeismicUnix < Formula
  desc "Seismic utilities from the Center for Wave Phenomena, "\
       "Colorado School of Mines"
  homepage "http://www.cwp.mines.edu/cwpcodes/"
  url "ftp://ftp.cwp.mines.edu/pub/cwpcodes/cwp_su_all_44R0.tgz"
  version "44R0"
  sha256 "e6bf4230673d0d327be6f01903fca41645d879198840464b9fc34616f4ffc71d"

  option "without-src",     "Do not install the source (includes demos)"
  option "without-xtapps",  "Do not build X-toolkit applications"
  option "with-xmapps",     "Build Motif applications"
  option "with-fortran",    "Build Fortran codes"
  option "with-glapps",     "Build Mesa/OpenGL applications"
  option "with-utils-lib",  "Build cwputils library"
  option "with-segdread",   "Build SEG-D and SEG-B read utilities"

  depends_on :x11 if build.with?("xtapps") || build.with?("xmapps") || \
    build.with?("glapps")

  # The Motif applications require lesstif (or openmotif).
  depends_on "lesstif" || "openmotif" if build.with?("xmapps")

  depends_on :fortran if build.with?("fortran")

  keg_only <<-EOF.undent
    Seismic Unix installs many commands that may conflict with other formulas.
  EOF

  def install
    ENV["CWPROOT"] = prefix
    prefix.mkpath

    # We build things under the prefix directory. The build process requires
    # the src directory to be available there. As per the installation
    # instructions, we create a symbolic link to the src directory in the
    # temporary location where the source code has been extracted. Later we
    # will remove this symbolic link.
    ln_s buildpath, prefix/"src"
    cd prefix/"src"

    ENV.append_to_cflags "-std=c90 -ansi -Wno-long-long"
    ENV.deparallelize
    if MacOS.version == :lion
      cp "configs/Makefile.config_MacOSX_Lion", "Makefile.config"
    end
    if MacOS.version == :mountain_lion
      cp "configs/Makefile.config_MacOSX_Lion", "Makefile.config"
    end
    if MacOS.version == :mavericks
      cp "configs/Makefile.config_MacOSX_Mavericks", "Makefile.config"
    end
    if MacOS.version == :yosemite
      cp "configs/Makefile.config_MacOSX_Yosemite", "Makefile.config"
    end

    # Set CC, C++, OPTC, FC, FOPTS
    optflags = "#{ENV["HOMEBREW_OPTFLAGS"]}"\
               " -#{ENV["HOMEBREW_OPTIMIZATION_LEVEL"]}"
    foptflags = "#{ENV["HOMEBREW_OPTFLAGS"]}"\
                " -#{ENV["HOMEBREW_OPTIMIZATION_LEVEL"]}"
    # The Fortran codes do not compile with the "-march=native" flag.
    foptflags.gsub! /-march=native/, ""
    inreplace "Makefile.config" do |s|
      s.gsub! /CC = .*/, "CC = #{ENV.cc}\nC++ = #{ENV.cxx}"
      s.change_make_var! "OPTC", "#{ENV.cflags} #{optflags}"
      s.change_make_var! "FC", "#{ENV.fc}"
      s.change_make_var! "FOPTS", "#{ENV.fflags} #{ENV.fcflags} #{foptflags}"
    end

    # Replace use of more program with cat in the license script to allow for
    # unattended builds.
    inreplace "license.sh", "more", "cat"

    #system "make", "install"
    # The make install target is defined in terms of other targets as follows:
    #
    # install: checkroot LICENSE_44_ACCEPTED MAILHOME_44 makedirs cwpstuff
    #          plot sustuff tristuff tetrastuff compstuff reflstuff
    #
    # We override this as follows:
    #
    # - We bypass the checkroot target as it runs a script and waits for input;
    #   the check on the CWPROOT variable is not necessary as it is defined
    #   above.
    # - We run the license-acceptance script directly with pre-supplied input
    #   to allow for unattended builds. Furthermore, we provide info about the
    #   license in the caveats section below.
    # - We bypass the mail-home target as it requires user input and interferes
    #   with unattended builds. Again, we provide info about this in the
    #   caveats section.
    # - We call the remaining targets directly.
    core_targets = ["makedirs", "cwpstuff", "plot", "sustuff", "tristuff",
                    "tetrastuff", "compstuff", "reflstuff"]
    system "echo \"\nyes\" | ./license.sh"
    system "make", *core_targets
    if build.with? "xtapps"
      system "make", "xtinstall"
    end
    if build.with? "xmapps"
      system "make", "xminstall"
    end
    if build.with? "fortran"
      system "make", "finstall"
    end
    if build.with? "glapps"
      system "make", "mglinstall"
    end
    if build.with? "utils-lib"
      system "make", "utils"
    end
    if build.with? "segdread"
      cd "Sfio" do
        system "make"
      end
    end

    # Remove the symbolic link to the source directory created above.
    rm prefix/"src"
    if build.with? "src"
      prefix.install Dir[buildpath]
    end

    # Create shell initialization files, especially important since we install
    # this as a keg-only formula.
    libexec.mkpath
    system "echo \"export CWPROOT=#{opt_prefix}\" > #{libexec}/seismic-unix.sh"
    system "echo \"export PATH=#{opt_prefix}/bin:\$PATH\" >>"\
           " #{libexec}/seismic-unix.sh"
    system "echo \"setenv CWPROOT #{opt_prefix}\" > #{libexec}/seismic-unix.csh"
    system "echo \"set path = ( #{opt_prefix}/bin \$path )\" >>"\
           " #{libexec}/seismic-unix.csh"
    etc.install libexec/"seismic-unix.sh" => etc/"seismic-unix.sh" unless \
      File.exist?(etc/"seismic-unix.sh")
    etc.install libexec/"seismic-unix.csh" => etc/"seismic-unix.csh" unless \
      File.exist?(etc/"seismic-unix.csh")
  end

  def caveats; <<-EOS.undent
    We agreed to the Colorado School of Mines License Agreement for you (it is
    a Free BSD style license). If this is unacceptable you should uninstall.

    For more information about the license, please see:
      http://www.cwp.mines.edu/cwpcodes/LEGAL_STATEMENT

    To give the developers of Seismic Unix at the Center for Wave Phenomena an
    idea of who uses the code, consider joining the CWP/SU mailing list. If you
    installed the Seismic Unix source, this can be accomplished by running the
    script:
      #{opt_prefix}/src/mailhome.sh

    To use Seismic Unix, you should add the following command to your shell
    initialization script (.bashrc/.profile/.zshrc/etc.), or call it directly
    before using Seismic Unix:

    - for bash/zsh users:
        source #{etc}/seismic-unix.sh
    - for csh/tcsh users:
       source #{etc}/seismic-unix.csh
    EOS
  end
end
