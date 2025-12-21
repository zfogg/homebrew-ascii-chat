class Libasciichat < Formula
  desc "Development libraries and documentation for ascii-chat"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.4.11"
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
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "325284c013a6f841bcca27942056b9b9bb639a447882fbe0fa752b3c44037c8e"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "ea5e82cebe912c97c5cdfdee1cfcbba947593b35d03a23314af2ed66b4f5a8c9"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "93834470fda9eb849efaa1db0ed60fd68fec377b097a169827445aa08834cc3e"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "5260aa27cd076e38f9e966b64dbd3dc013ae635b28ad0c6d57c3502c7ec4847f"
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
      working_dir = Dir.exist?("bin") ? "." : Dir["ascii-chat-*"].first
      raise "Could not find ascii-chat directory" unless working_dir

      cd working_dir do
        include.install Dir["include/*"]
        lib.install Dir["lib/*"]
        man3.install Dir["share/man/man3/*"]
        doc.install "share/doc/ascii-chat/html"
      end
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
