class Unbound < Formula
  desc "Validating, recursive, caching DNS resolver"
  homepage "https://www.unbound.net"
  url "https://www.unbound.net/downloads/unbound-1.6.8.tar.gz"
  sha256 "e3b428e33f56a45417107448418865fe08d58e0e7fea199b855515f60884dd49"

  bottle do
    sha256 "14bb3f5ce9567f835522a4cf278e843602def948c9c139c0dbe660dad666b6e9" => :high_sierra
    sha256 "aa344f2853ef983890eed1eecd53c06e0c41e491253f8480bc944c62edc7ccc4" => :sierra
    sha256 "8854838cff0d79d0b855b95c588588dc95b5eb1bda3a1db019717d832eebf35b" => :el_capitan
    sha256 "8a15385a1ad682b3e90cff696ea2c3327e3bb4b7c19d304479768ad6b7be7e0b" => :x86_64_linux
  end

  deprecated_option "with-python" => "with-python@2"

  depends_on "openssl"
  depends_on "libevent"
  depends_on "expat" unless OS.mac?

  depends_on "python@2" => :optional
  depends_on "swig" if build.with?("python@2")

  def install
    args = %W[
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --with-libevent=#{Formula["libevent"].opt_prefix}
      --with-ssl=#{Formula["openssl"].opt_prefix}
    ]

    if build.with? "python@2"
      ENV.prepend "LDFLAGS", `python-config --ldflags`.chomp
      ENV.prepend "PYTHON_VERSION", "2.7"

      args << "--with-pyunbound"
      args << "--with-pythonmodule"
      args << "PYTHON_SITE_PKG=#{lib}/python2.7/site-packages"
    end

    if OS.mac?
      args << "--with-libexpat=#{MacOS.sdk_path}/usr" unless MacOS::CLT.installed?
    else
      args << "--with-libexpat=#{Formula["expat"].prefix}"
    end
    system "./configure", *args

    inreplace "doc/example.conf", 'username: "unbound"', 'username: "@@HOMEBREW-UNBOUND-USER@@"'
    system "make"
    system "make", "test"
    system "make", "install"
  end

  def post_install
    conf = etc/"unbound/unbound.conf"
    return unless conf.exist?
    return unless conf.read.include?('username: "@@HOMEBREW-UNBOUND-USER@@"')
    inreplace conf, 'username: "@@HOMEBREW-UNBOUND-USER@@"',
                    "username: \"#{ENV["USER"]}\""
  end

  plist_options :startup => true

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-/Apple/DTD PLIST 1.0/EN" "http:/www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_sbin}/unbound</string>
          <string>-d</string>
          <string>-c</string>
          <string>#{etc}/unbound/unbound.conf</string>
        </array>
        <key>UserName</key>
        <string>root</string>
        <key>StandardErrorPath</key>
        <string>/dev/null</string>
        <key>StandardOutPath</key>
        <string>/dev/null</string>
      </dict>
    </plist>
    EOS
  end

  test do
    system sbin/"unbound-control-setup", "-d", testpath
  end
end
