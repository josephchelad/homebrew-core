class Rust < Formula
  desc "Safe, concurrent, practical language"
  homepage "https://www.rust-lang.org/"

  stable do
    url "https://static.rust-lang.org/dist/rustc-1.24.1-src.tar.gz"
    sha256 "3ea53d45e8d2e9a41afb3340cf54b9745f845b552d802d607707cf04450761ef"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git",
          :tag => "0.25.0",
          :revision => "8c93e089536467783957fec23b0f2627bb6ce357"
    end

    resource "racer" do
      url "https://github.com/racer-rust/racer/archive/2.0.12.tar.gz"
      sha256 "1fa063d90030c200d74efb25b8501bb9a5add7c2e25cbd4976adf7a73bf715cc"
    end
  end

  bottle do
    rebuild 1 unless OS.mac?
    sha256 "47eb6c2033982c0e69c4f26b7e3064452bb6c39dc20dc25b4b63a7b0eca64856" => :high_sierra
    sha256 "fb7409f7ae34f136199a19dfe93e9a69c8fa67f3e1f7e35ca0e436a20acdb0a1" => :sierra
    sha256 "f098dfc90d7630bb6909ce919d71b655543cf39fca194b684b1dabeac0cb8f52" => :el_capitan
    sha256 "b4c725ae9794f764b6492a3f132e51919b5aea0af1d83e4fdd138677cb864811" => :x86_64_linux
  end

  head do
    url "https://github.com/rust-lang/rust.git"

    resource "cargo" do
      url "https://github.com/rust-lang/cargo.git"
    end
  end

  option "with-llvm", "Build with brewed LLVM. By default, Rust's LLVM will be used."
  option "with-racer", "Build Racer code completion tool, and retain Rust sources."

  depends_on "cmake" => :build
  depends_on "pkg-config"
  depends_on "llvm" => :optional
  depends_on "openssl"
  depends_on "libssh2"

  unless OS.mac?
    depends_on "binutils"
    depends_on "curl"
    depends_on "python@2"
    depends_on "zlib"
  end

  conflicts_with "cargo-completion", :because => "both install shell completion for cargo"

  # According to the official readme, GCC 4.7+ is required
  fails_with :gcc_4_0
  fails_with :gcc
  ("4.3".."4.6").each do |n|
    fails_with :gcc => n
  end

  resource "cargobootstrap" do
    if OS.mac?
      # From https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2018-01-04/cargo-0.24.0-x86_64-apple-darwin.tar.gz"
      sha256 "b6f7c662ea75a94f5a5e41c2fee95f09a5ba168429ac8cdd41f6ba2c78d1b07f"
    elsif OS.linux?
      # From: https://github.com/rust-lang/rust/blob/#{version}/src/stage0.txt
      url "https://static.rust-lang.org/dist/2018-01-04/cargo-0.24.0-x86_64-unknown-linux-gnu.tar.gz"
      sha256 "ff8a454104aba20426ea898ed7515ec5da7de07d11733cdda17462455beb76e8"
    end
  end

  def install
    # Reduce memory usage below 4 GB for Circle CI.
    ENV["MAKEFLAGS"] = "-j1 -l2.0" if ENV["CIRCLECI"]

    # Fix build failure for compiler_builtins "error: invalid deployment target
    # for -stdlib=libc++ (requires OS X 10.7 or later)"
    ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version if OS.mac?

    # Prevent cargo from linking against a different library (like openssl@1.1)
    # from libssh2 and causing segfaults
    ENV["OPENSSL_INCLUDE_DIR"] = Formula["openssl"].opt_include
    ENV["OPENSSL_LIB_DIR"] = Formula["openssl"].opt_lib

    # Fix build failure for cmake v0.1.24 "error: internal compiler error:
    # src/librustc/ty/subst.rs:127: impossible case reached" on 10.11, and for
    # libgit2-sys-0.6.12 "fatal error: 'os/availability.h' file not found
    # #include <os/availability.h>" on 10.11 and "SecTrust.h:170:67: error:
    # expected ';' after top level declarator" among other errors on 10.12
    ENV["SDKROOT"] = MacOS.sdk_path if OS.mac?

    args = ["--prefix=#{prefix}"]
    args << "--disable-rpath" if build.head?
    args << "--llvm-root=#{Formula["llvm"].opt_prefix}" if build.with? "llvm"
    if build.head?
      args << "--release-channel=nightly"
    else
      args << "--release-channel=stable"
    end
    system "./configure", *args
    system "make"
    system "make", "install"

    resource("cargobootstrap").stage do
      system "./install.sh", "--prefix=#{buildpath}/cargobootstrap"
    end
    ENV.prepend_path "PATH", buildpath/"cargobootstrap/bin"

    resource("cargo").stage do
      ENV["RUSTC"] = bin/"rustc"
      system "cargo", "build", "--release", "--verbose"
      bin.install "target/release/cargo"
    end

    if build.with? "racer"
      resource("racer").stage do
        ENV.prepend_path "PATH", bin
        cargo_home = buildpath/"cargo_home"
        cargo_home.mkpath
        ENV["CARGO_HOME"] = cargo_home
        system bin/"cargo", "build", "--release", "--verbose"
        (libexec/"bin").install "target/release/racer"
        (bin/"racer").write_env_script(libexec/"bin/racer", :RUST_SRC_PATH => pkgshare/"rust_src")
      end
      # Remove any binary files; as Homebrew will run ranlib on them and barf.
      rm_rf Dir["src/{llvm,test,librustdoc,etc/snapshot.pyc}"]
      (pkgshare/"rust_src").install Dir["src/*"]
    end

    rm_rf prefix/"lib/rustlib/uninstall.sh"
    rm_rf prefix/"lib/rustlib/install.log"
  end

  def post_install
    Dir["#{lib}/rustlib/**/*.dylib"].each do |dylib|
      chmod 0664, dylib
      MachO::Tools.change_dylib_id(dylib, "@rpath/#{File.basename(dylib)}")
      chmod 0444, dylib
    end
  end

  test do
    system "#{bin}/rustdoc", "-h"
    (testpath/"hello.rs").write <<~EOS
      fn main() {
        println!("Hello World!");
      }
    EOS
    system "#{bin}/rustc", "hello.rs"
    assert_equal "Hello World!\n", `./hello`
    system "#{bin}/cargo", "new", "hello_world", "--bin"
    assert_equal "Hello, world!",
                 (testpath/"hello_world").cd { `#{bin}/cargo run`.split("\n").last }
  end
end
