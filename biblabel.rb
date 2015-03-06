class Biblabel < Formula
  homepage "http://www.math.utah.edu/pub/biblabel"
  url "http://ftp.math.utah.edu/pub/biblabel/biblabel-0.07.tar.gz"
  version "0.07"
  sha1 "cd01d0dee5aa6deead87f86528abe2f5769131bb"

  depends_on "bibclean"

  def install
    ENV.deparallelize  # if your formula fails when building in parallel

    bin.mkpath
    man1.mkpath
    ENV["AWK"] = "/usr/bin/awk"
    system "./configure", "--prefix=#{prefix}"
    system "make", "all"
    system "make", "check"
    system "make", "LIBDIR=#{prefix}/share",
                   "MANDIR=#{man1}",
                   "install"
  end
end
