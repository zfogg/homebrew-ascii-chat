class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.6.0"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Runtime dependencies - prebuilt binaries are dynamically linked against Homebrew libraries
  depends_on "abseil"
  depends_on "ca-certificates"
  depends_on "ffmpeg"
  depends_on "gnupg"
  depends_on "libsodium"
  depends_on "mimalloc"
  depends_on "opus"
  depends_on "portaudio"
  depends_on "sqlite"
  depends_on "zstd"

  # Additional build dependencies only needed when building from source (--HEAD)
  head do
    depends_on "cmake" => :build
    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "ninja" => :build
  end

  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "1bd32722aada3aa6bfa91e8639420640565ca45f1ce790435240d86ed53ac3b5"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "fdb2c6c6e4ef24ab547b29ca79e10f1153a31e11f0bdb27f440185eb5458fc09"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "de404f0f8cd02abc3456ab4ecdcfd1fe318705c47be7409329f05fac1a50efa5"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "0f90e6279d2474629c0f3849aca29e6d319f1286204b91fa7f63b149d5780c4f"
    end
  end

  # GPG signature verification resources
  resource "sig-macos-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.6.0/ascii-chat-0.6.0-macOS-arm64.tar.gz.asc"
    sha256 "ffe85b88373b478c0e5d3b75e0b0a324316fb3f730acf3e252ca9ce03f5225ce"
  end

  resource "sig-macos-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.6.0/ascii-chat-0.6.0-macOS-amd64.tar.gz.asc"
    sha256 "a5263c1144cca3fcd910433a6e368bde083f4cc75c9697a25b3c0805b12c6e1d"
  end

  resource "sig-linux-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.6.0/ascii-chat-0.6.0-Linux-arm64.tar.gz.asc"
    sha256 "22e370cc446ac539f30962edbdea048f62f7072600ac3be9177fe844acd1149e"
  end

  resource "sig-linux-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.6.0/ascii-chat-0.6.0-Linux-amd64.tar.gz.asc"
    sha256 "53853711f453f428ea7521ceb866064e2296db6a369294a6dfbbebf5844c6da8"
  end

  # Homebrew service for running ascii-chat server
  # Start: brew services start ascii-chat
  # Stop: brew services stop ascii-chat
  # Configure: edit ~/.config/ascii-chat/config.toml
  # Generate config: ascii-chat --config-create
  service do
    run [opt_bin/"ascii-chat", "server"]
    keep_alive crashed: true
    working_dir var
    log_path var/"log/ascii-chat.log"
    error_log_path var/"log/ascii-chat.log"
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

      # Set up paths for Homebrew dependencies
      llvm_lib = Formula["llvm"].opt_lib
      ENV["LDFLAGS"] = "-L#{HOMEBREW_PREFIX}/lib -L#{llvm_lib}/unwind -lunwind"
      ENV["CPPFLAGS"] = "-I#{HOMEBREW_PREFIX}/include"
      ENV["PKG_CONFIG_PATH"] = "#{HOMEBREW_PREFIX}/lib/pkgconfig:#{HOMEBREW_PREFIX}/share/pkgconfig"

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
      cmake_args = [
        "-B", "build", "-S", ".", "-G", "Ninja",
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_INSTALL_PREFIX=#{prefix}",
        "-DCMAKE_OSX_SYSROOT=#{sdk_path}",
        "-DCMAKE_OBJC_COMPILER=#{llvm_bin}/clang",
        "-DCMAKE_OBJCXX_COMPILER=#{llvm_bin}/clang++",
        "-DCMAKE_EXE_LINKER_FLAGS=-L#{HOMEBREW_PREFIX}/lib -L#{llvm_lib}/unwind -lunwind",
        "-DCMAKE_SHARED_LINKER_FLAGS=-L#{HOMEBREW_PREFIX}/lib",
        "-DASCIICHAT_SHARED_DEPS=ON",
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
        "-DASCIICHAT_LLD_EXECUTABLE=#{Formula["lld"].opt_bin}/ld.lld",
      ]

      system "cmake", *cmake_args

      # Build the shared library first
      ohai "Building libasciichat shared library..."
      system "cmake", "--build", "build", "--target", "shared-lib"
      system "cmake", "--build", "build", "--target", "static-lib"

      # Install the library components
      ohai "Installing libasciichat..."
      system "cmake", "--install", "build", "--component", "Unspecified"
      system "cmake", "--install", "build", "--component", "Development"
      system "cmake", "--install", "build", "--component", "Manpages"

      # Build the ascii-chat binary (links against the library we just built)
      ohai "Building ascii-chat binary..."
      system "cmake", "--build", "build", "--target", "ascii-chat"
      system "cmake", "--build", "build", "--target", "man1"

      # Install the binary and related files
      bin.install "build/bin/ascii-chat"
      man1.install "build/share/man/man1/ascii-chat.1"
      bash_completion.install "share/bash-completion/completions/ascii-chat"
      zsh_completion.install "share/zsh/site-functions/_ascii-chat"
      fish_completion.install "share/fish/vendor_completions.d/ascii-chat.fish"
    else
      working_dir = Dir.exist?("bin") ? "." : Dir["ascii-chat-*"].first
      raise "Could not find ascii-chat directory" unless working_dir

      cd working_dir do
        bin.install Dir["bin/*"]
        man1.install Dir["share/man/man1/*"]
        bash_completion.install "share/bash-completion/completions/ascii-chat"
        zsh_completion.install "share/zsh/site-functions/_ascii-chat"
        fish_completion.install "share/fish/vendor_completions.d/ascii-chat.fish"
      end
    end
  end

  def caveats
    <<~EOS
      To run ascii-chat server as a background service:
        brew services start ascii-chat

      Before starting the service, create a config file:
        ascii-chat --config-create

      Then edit ~/.config/ascii-chat/config.toml to configure your server.

      Service logs are written to:
        #{var}/log/ascii-chat.log

      Development library (libasciichat) installed to:
        Headers: #{include}/ascii-chat
        Library: #{lib}/libasciichat.dylib
        Docs:    https://zfogg.github.io/ascii-chat/
    EOS
  end

  test do
    # Test the binary
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1")

    # Test linking against the library
    (testpath/"test.c").write <<~EOS
      #include <ascii-chat/log/logging.h>
      int main() {
        log_init(NULL, LOG_INFO, true, false);
        log_info("libasciichat test");
        log_destroy();
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-I#{include}/ascii-chat", "-L#{lib}", "-lasciichat", "-o", "test"
    assert_match "libasciichat test", shell_output("./test 2>&1")
  end
end
