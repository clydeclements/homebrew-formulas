class Pdftk < Formula
  desc "PDFtk Server - The PDF Toolkit for the Terminal"
  homepage 'http://www.pdflabs.com/tools/pdftk-server/'
  version '2.02'
  url "http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/pdftk_server-#{version}-mac_osx-10.6-setup.pkg"
  sha256 'c0679a7a12669480dd298c436b0e4d063966f95ed6a77b98d365bb8c86390d1b'

  def install
    ohai "Extracting payload contents"
    system "gunzip < pdftk.pkg/Payload | cpio -i -"

    bin.mkpath
    lib.mkpath
    man1.mkpath
    doc.mkpath
    bin.install "bin/pdftk"
    lib.install "lib/libgcc_s.1.dylib"
    lib.install "lib/libgcj.11.dylib"
    lib.install "lib/libiconv.2.dylib"
    lib.install "lib/libstdc++.6.dylib"
    man1.install "man/pdftk.1"
    doc.install "changelog.html"
    doc.install "changelog.txt"
    doc.install "man/pdftk.1.html"
    doc.install "man/pdftk.1.txt"
    doc.install Dir["license*"]
  end
end
