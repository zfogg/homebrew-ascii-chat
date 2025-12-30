class Libasciichat < Formula
  desc "Development libraries and documentation for ascii-chat"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.5.64"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Runtime dependencies needed when linking against the library
  depends_on "zstd"
  depends_on "libsodium"
  depends_on "opus"
  depends_on "mimalloc"
  depends_on "portaudio"

  # GPG needed for signature verification
  depends_on "gnupg" => :build

  # Build dependencies only needed when building from source (--HEAD)
  if build.head?
    depends_on "cmake" => :build
    depends_on "doxygen" => :build
    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "ninja" => :build
    depends_on "criterion" => :test
  end

  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-macOS-arm64.tar.gz"
      sha256 "2148c1821904a961a36c7aae3c4e5cb26859fdcce71d917238e522148019c181"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-macOS-amd64.tar.gz"
      sha256 "82c18d61d64fe26aba27f18599c094572f78085165e57c67d169329457c1cf70"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-Linux-arm64.tar.gz"
      sha256 "e930e2ecb6e4dd38f867fd8963f982a5738bee3985d503798c29b27b7a246afb"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/libasciichat-#{version}-Linux-amd64.tar.gz"
      sha256 "d9d62b59fa30a5db1f08d580773886e76cf4ecd7d7af0dce614b1187e04d3ee1"
    end
  end

  # GPG signature verification resources
  resource "sig-macos-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/libasciichat-0.5.64-macOS-arm64.tar.gz.asc"
    sha256 "45c868a828e43d27edae9fb6d83e863e889d020980596ef443824d97bd21d27e"
  end

  resource "sig-macos-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/libasciichat-0.5.64-macOS-amd64.tar.gz.asc"
    sha256 "a39f8c01d79da0e6da572920690e9a537cf9f7364b3082bc28e56c8fb42df722"
  end

  resource "sig-linux-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/libasciichat-0.5.64-Linux-arm64.tar.gz.asc"
    sha256 "2dc9b8c4dd11b5850051bfb996607c506bd9640bc182c6e4f59c1c29d7417a4d"
  end

  resource "sig-linux-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/libasciichat-0.5.64-Linux-amd64.tar.gz.asc"
    sha256 "979a02b8333a1f0ba26ddfbf835f2e9cc28067b555fe1b7e1fdbdfcad87a6d47"
  end

  def install
    unless build.head?
      # Import GPG public key for signature verification
      gpg_key = "F315D1B948F33B2102FBD7B6B95124621822044A"
      system "gpg", "--keyserver", "keyserver.ubuntu.com", "--recv-keys", gpg_key

      # Determine which signature resource to use based on platform
      sig_resource = if OS.mac?
        Hardware::CPU.arm? ? "sig-macos-arm64" : "sig-macos-amd64"
      else
        Hardware::CPU.arm? ? "sig-linux-arm64" : "sig-linux-amd64"
      end

      # Download and verify signature
      resource(sig_resource).stage do
        sig_file = Dir["*.asc"].first
        tarball = cached_download
        system "gpg", "--verify", sig_file, tarball
        ohai "GPG signature verification successful"
      end
    end

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
