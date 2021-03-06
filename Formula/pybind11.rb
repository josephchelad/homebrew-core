class Pybind11 < Formula
  desc "Seamless operability between C++11 and Python"
  homepage "https://github.com/pybind/pybind11"
  url "https://github.com/pybind/pybind11/archive/v2.2.2.tar.gz"
  sha256 "b639a2b2cbf1c467849660801c4665ffc1a4d0a9e153ae1996ed6f21c492064e"
  revision 1

  bottle do
    cellar :any_skip_relocation
    sha256 "6dc411ca7b69e89a1abf2ee6c439b7f067fed8ee846dc3220d9e80d4d8f6727a" => :high_sierra
    sha256 "6dc411ca7b69e89a1abf2ee6c439b7f067fed8ee846dc3220d9e80d4d8f6727a" => :sierra
    sha256 "6dc411ca7b69e89a1abf2ee6c439b7f067fed8ee846dc3220d9e80d4d8f6727a" => :el_capitan
  end

  depends_on "cmake" => :build
  depends_on "python"

  def install
    system "cmake", ".", "-DPYBIND11_TEST=OFF", *std_cmake_args
    system "make", "install"
  end

  test do
    (testpath/"example.cpp").write <<~EOS
      #include <pybind11/pybind11.h>

      int add(int i, int j) {
          return i + j;
      }
      namespace py = pybind11;
      PYBIND11_PLUGIN(example) {
          py::module m("example", "pybind11 example plugin");
          m.def("add", &add, "A function which adds two numbers");
          return m.ptr();
      }
    EOS

    (testpath/"example.py").write <<~EOS
      import example
      example.add(1,2)
    EOS

    python_flags = `python3-config --cflags --ldflags`.split(" ")
    system ENV.cxx, "-O3", "-shared", "-std=c++11", *python_flags, *("-fPIC" unless OS.mac?), "example.cpp", "-o", "example.so"
    system "python3", "example.py"
  end
end
