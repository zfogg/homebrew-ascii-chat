class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  url "https://github.com/zfogg/ascii-chat/releases/download/v0.3.15/ascii-chat-0.3.15-full.tar.gz"
  sha256 "71066ddf5fd19fb6727a3420ee452531eceae15a9c2662c9ee7cef5ff39b1ad2"
  license "MIT"
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "libsodium" => :build
  depends_on "lld" => :build
  depends_on "llvm" => :build
  depends_on "mimalloc" => :build
  depends_on "ninja" => :build
  depends_on "portaudio" => :build
  depends_on "zstd" => :build

  def install
    if build.head?
      system "git", "submodule", "update", "--init", "--recursive"
    else
      # Create a real git repo with the version tag so git describe works
      system "git", "init", "-q"
      system "git", "config", "user.email", "build@localhost"
      system "git", "config", "user.name", "Build"
      system "git", "add", "-A"
      system "git", "commit", "-q", "-m", "v#{version}"
      system "git", "tag", "v#{version}"
    end

    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
           "-DCMAKE_BUILD_TYPE=Release",
           "-DCMAKE_INSTALL_PREFIX=#{prefix}",
           "-DASCIICHAT_LLVM_CONFIG_EXECUTABLE=#{Formula["llvm"].opt_bin}/llvm-config",
           "-DASCIICHAT_LLD_EXECUTABLE=#{Formula["lld"].opt_bin}/ld.lld"

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
