class Libasciichat < Formula
  desc "Development libraries and documentation for ascii-chat"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.4.12"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "libsodium" => :build
  depends_on "lld" => :build
  depends_on "llvm" => :build
  depends_on "mimalloc" => :build
  depends_on "ninja" => :build
  depends_on "opus" => :build
  depends_on "portaudio" => :build
  depends_on "zstd" => :build
  depends_on "criterion" => :test

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
      ENV["OBJC"] = Formula["llvm"].opt_bin/"clang"
      ENV["OBJCXX"] = Formula["llvm"].opt_bin/"clang++"

      # Use Homebrew LLVM's bundled libunwind (from brew info llvm)
      llvm_lib = Formula["llvm"].opt_lib
      ENV["LDFLAGS"] = "-L#{llvm_lib}/unwind -lunwind"

      # Download pre-built defer tool from build-tools release
      # This avoids building the defer tool from source, which requires matching LLVM versions
      defer_tool_dir = buildpath/".deps-cache/defer-tool"
      defer_tool_dir.mkpath
      defer_tool_path = defer_tool_dir/"ascii-instr-defer"

      # Download the macOS universal binary
      defer_url = "https://github.com/zfogg/ascii-chat/releases/download/build-tools/ascii-instr-defer.macOS.universal"
      system "curl", "-fsSL", "-o", defer_tool_path, defer_url
      defer_tool_path.chmod 0755
      ohai "Downloaded pre-built defer tool from build-tools release"

      # Get macOS SDK path for Homebrew LLVM
      sdk_path = Utils.safe_popen_read("xcrun", "--show-sdk-path").chomp

      llvm_bin = Formula["llvm"].opt_bin
      system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_INSTALL_PREFIX=#{prefix}",
             "-DCMAKE_OSX_SYSROOT=#{sdk_path}",
             "-DCMAKE_OBJC_COMPILER=#{llvm_bin}/clang",
             "-DCMAKE_OBJCXX_COMPILER=#{llvm_bin}/clang++",
             "-DASCIICHAT_DEFER_TOOL=#{defer_tool_path}",
             "-DASCIICHAT_ENABLE_ANALYZERS=OFF",
             "-DASCIICHAT_LLVM_CONFIG_EXECUTABLE=#{llvm_bin}/llvm-config",
             "-DASCIICHAT_CLANG_EXECUTABLE=#{llvm_bin}/clang",
             "-DASCIICHAT_CLANG_PLUS_PLUS_EXECUTABLE=#{llvm_bin}/clang++",
             "-DASCIICHAT_LLVM_AR_EXECUTABLE=#{llvm_bin}/llvm-ar",
             "-DASCIICHAT_LLVM_RANLIB_EXECUTABLE=#{llvm_bin}/llvm-ranlib",
             "-DASCIICHAT_LLVM_NM_EXECUTABLE=#{llvm_bin}/llvm-nm",
             "-DASCIICHAT_LLVM_READELF_EXECUTABLE=#{llvm_bin}/llvm-readelf",
             "-DASCIICHAT_LLVM_OBJDUMP_EXECUTABLE=#{llvm_bin}/llvm-objdump",
             "-DASCIICHAT_LLVM_STRIP_EXECUTABLE=#{llvm_bin}/llvm-strip",
             "-DASCIICHAT_LLD_EXECUTABLE=#{Formula["lld"].opt_bin}/ld.lld"

      system "cmake", "--build", "build", "--target", "shared-lib"
      system "cmake", "--build", "build", "--target", "static-lib"
      system "cmake", "--build", "build", "--target", "docs"

      # Install library components (not Runtime which is the main binary)
      system "cmake", "--install", "build", "--component", "Unspecified"
      system "cmake", "--install", "build", "--component", "Development"
      system "cmake", "--install", "build", "--component", "Documentation"
      system "cmake", "--install", "build", "--component", "Manpages"
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
      #include <ascii-chat/log/logging.h>
      int main() {
        log_init(NULL, LOG_INFO, true, false);
        log_info("libasciichat test");
        log_destroy();
        return 0;
      }
    EOS
    # Need both include paths: one for <ascii-chat/...> and one for internal relative includes
    system ENV.cc, "test.c", "-I#{include}", "-I#{include}/ascii-chat", "-L#{lib}", "-lasciichat", "-o", "test"
    assert_match "libasciichat test", shell_output("./test 2>&1")
  end
end
