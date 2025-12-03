class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  url "https://github.com/zfogg/ascii-chat/releases/download/v0.3.12/ascii-chat-0.3.12-full.tar.gz"
  sha256 "8fd96a4eb28d336491fb9121a7544f7f58190398cd67f6b04ed4a5e4ce1b6cb4"
  license "MIT"
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "llvm" => :build
  depends_on "mimalloc" => :build
  depends_on "portaudio" => :build
  depends_on "libsodium" => :build
  depends_on "zstd" => :build
  depends_on "doxygen" => :build

  def install
    if build.head?
      system "git", "submodule", "update", "--init", "--recursive"
    else
      # Full tarball includes submodules, just set up git for version detection
      mkdir_p ".git"
      File.write(".git/HEAD", "ref: refs/tags/v#{version}")
      FileUtils.touch(".git/index")
    end

    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
           "-DCMAKE_BUILD_TYPE=Release",
           "-DCMAKE_INSTALL_PREFIX=#{prefix}"

    system "cmake", "--build", "build", "--target", "ascii-chat"
    system "cmake", "--build", "build", "--target", "shared-lib"
    system "cmake", "--build", "build", "--target", "static-lib"
    system "cmake", "--build", "build", "--target", "docs"

    system "cmake", "--install", "build"
  end

  test do
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1", 1)
  end
end
