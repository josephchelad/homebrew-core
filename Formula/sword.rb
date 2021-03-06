class Sword < Formula
  desc "Cross-platform tools to write Bible software"
  homepage "https://www.crosswire.org/sword/index.jsp"
  url "https://www.crosswire.org/ftpmirror/pub/sword/source/v1.8/sword-1.8.1.tar.gz"
  sha256 "ce9aa8f721a737f406115d35ff438bd07c829fce1605f0d6dcdabc4318bc5e93"

  bottle do
    sha256 "3279c77477c21d1636f573202df976bd37fbaca39ed7e3b310158dad4e961641" => :high_sierra
    sha256 "794afe687eb7933fd3aeaee7e480224295614fc0138b8d89b7d9b81be55239a1" => :sierra
    sha256 "032c83b3302b78c198d1e346258a1d09c542a1361e1b0f000f82306d8c82acb4" => :el_capitan
    sha256 "daa1f0360c2a9b72ecdba5ca9574bfe9688f4c852d1313456502a2538b93b1e7" => :x86_64_linux
  end

  option "with-clucene", "Use clucene for text searching capabilities"
  option "with-icu4c", "Use icu4c for unicode support"

  depends_on "clucene" => :optional
  depends_on "icu4c" => :optional

  def install
    args = %W[
      --prefix=#{prefix}
      --disable-debug
      --disable-profile
      --disable-tests
      --with-curl
    ]

    if build.with? "icu4c"
      args << "--with-icu"
    else
      args << "--without-icu"
    end

    if build.with? "clucene"
      args << "--with-clucene"
    else
      args << "--without-clucene"
    end

    system "./configure", *args
    system "make", "install"
  end

  test do
    # This will call sword's module manager to list remote sources.
    # It should just demonstrate that the lib was correctly installed
    # and can be used by frontends like installmgr.
    system "#{bin}/installmgr", "-s"
  end
end
