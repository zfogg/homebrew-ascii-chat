class Libasciichat < Formula
  desc "Development libraries and documentation for ascii-chat"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.4.12"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master" do
    depends_on "cmake" => :build
    depends_on "doxygen" => :build
    depends_on "libsodium" => :build
    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "mimalloc" => :build
    depends_on "ninja" => :build
    depends_on "portaudio" => :build
    depends_on "zstd" => :build
  end

  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-macOS-arm64.tar.gz"
      sha256 "0a507bacd9439757eb4e5163859b9aa0e30b3859ee7fd86c2083ddebdb42339c"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-macOS-amd64.tar.gz"
      sha256 "7c74d2cd5db934b8ef672443a7b0864f54eb09371f6efdf7941657648110231d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-Linux-arm64.tar.gz"
      sha256 "93834470fda9eb849efaa1db0ed60fd68fec377b097a169827445aa08834cc3e"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-Linux-amd64.tar.gz"
      sha256 "346bc0e1a9328ffb16d53e04f1157452e1f809dd83c78eb27ce3d002f3cfe628"
    end
  end

  def install
    if build.head?
      system "git", "submodule", "update", "--init", "--recursive"

      ENV["CC"] = Formula["llvm"].opt_bin/"clang"
      ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

      system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_INSTALL_PREFIX=#{prefix}",
             "-DASCIICHAT_LLVM_CONFIG_EXECUTABLE=#{Formula["llvm"].opt_bin}/llvm-config",
             "-DASCIICHAT_LLD_EXECUTABLE=#{Formula["lld"].opt_bin}/ld.lld"

      system "cmake", "--build", "build", "--target", "shared-lib"
      system "cmake", "--build", "build", "--target", "static-lib"
      system "cmake", "--build", "build", "--target", "docs"

      system "cmake", "--install", "build"
    else
      # Package extracts directly with include/, lib/, etc. at the root
      include.install Dir["include/*"]
      lib.install Dir["lib/*"]
      man3.install Dir["share/man/man3/*"]
      doc.install "share/doc/ascii-chat/html"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <asciichat/log.h>
      int main() {
        log_info("libasciichat test");
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lasciichat", "-o", "test"
    assert_match "libasciichat test", shell_output("./test 2>&1")
  end
end
