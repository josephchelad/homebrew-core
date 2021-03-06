class Lmdb < Formula
  desc "Lightning memory-mapped database: key-value data store"
  homepage "https://symas.com/mdb-and-sqlite/"
  url "https://github.com/LMDB/lmdb/archive/LMDB_0.9.21.tar.gz"
  sha256 "1187b635a4cc415bb6972bba346121f81edd996e99b8f0816151d4090f90b559"
  version_scheme 1
  revision 1 if OS.linux?
  head "https://github.com/LMDB/lmdb.git", :branch => "mdb.master"

  bottle do
    cellar :any
    sha256 "dec11100f72b3dacd2c8da3679d9078b3badaeac42c6259e1f79894e4482d9db" => :high_sierra
    sha256 "f7d8acade2be32886edf1d039e57070e35db0bdeca6f37ef7f42530ad404cc91" => :sierra
    sha256 "b4dd9a1387599e22744bbb769ce71fd1588e5ea6f1ef1d83a2d32f71190cb6ff" => :el_capitan
    sha256 "66e48198e7bf2a466a614727a71b10e3b865cf1f65451fe10c7d5d4068e46a5c" => :yosemite
    sha256 "b5b5bcbaa6df4b52fc2b36772ec42b4e076192f5b922a272830af6c3d609ac26" => :x86_64_linux
  end

  def install
    cd "libraries/liblmdb" do
      args = *("SOEXT=.dylib" if OS.mac?)
      system "make", *args
      system "make", "test", *args
      system "make", "install", "prefix=#{prefix}", *args
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/mdb_dump -V")
  end
end
