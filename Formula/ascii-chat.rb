class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.5.64"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Only gnupg is needed for binary installs (signature verification)
  depends_on "gnupg" => :build

  # Build dependencies only needed when building from source (--HEAD)
  if build.head?
    depends_on "cmake" => :build
    depends_on "libsodium" => :build
    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "mimalloc" => :build
    depends_on "ninja" => :build
    depends_on "opus" => :build
    depends_on "portaudio" => :build
    depends_on "zstd" => :build
    depends_on "criterion" => :test
  end

  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "aadb8251a141d3c9a68654578532467f3ba0c8373df955c80f98191cb91889a0"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "1c681977c2d9925132ef39c41e51b4cb28b650a6630b1d96e3c5b9000cbfae19"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "04d559eea95bb99d6a1c6ea0082ab1b7da28ead5fc75b20d01d5967be287f08c"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "ab4e25c54dbb07b6a4108aaaa113a71d74c9d23974c0a59ccd92d7a8b674c382"
    end
  end

  # GPG signature verification resources
  resource "sig-macos-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/ascii-chat-0.5.64-macOS-arm64.tar.gz.asc"
    sha256 "ae65dce5131d3bbeeec9abafdcaae03b6a1f9dc16113aeb014f035ba23634a6b"
  end

  resource "sig-macos-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/ascii-chat-0.5.64-macOS-amd64.tar.gz.asc"
    sha256 "498459f956b4507ca1dc1b63fabd10d86edaa4c83da99e5bc4d0faf389da6a1f"
  end

  resource "sig-linux-arm64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/ascii-chat-0.5.64-Linux-arm64.tar.gz.asc"
    sha256 "57cfa5932b6d4f9bd9af580bdbd9a688976bbda85268517c17a44096ab5c7503"
  end

  resource "sig-linux-amd64" do
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.5.64/ascii-chat-0.5.64-Linux-amd64.tar.gz.asc"
    sha256 "2930c0d1cf703e05a97e8975eae49cc9fff192517527fcd8c7f65fcec9fd7713"
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
      cmake_args = [
        "-B", "build", "-S", ".", "-G", "Ninja",
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
        "-DASCIICHAT_LLD_EXECUTABLE=#{Formula["lld"].opt_bin}/ld.lld",
      ]

      system "cmake", *cmake_args

      system "cmake", "--build", "build", "--target", "ascii-chat"
      system "cmake", "--build", "build", "--target", "man1"

      bin.install "build/bin/ascii-chat"
      man1.install "build/docs/ascii-chat.1"
      bash_completion.install "share/completions/ascii-chat.bash" => "ascii-chat"
      zsh_completion.install "share/completions/_ascii-chat"
      fish_completion.install "share/completions/ascii-chat.fish"

      (prefix/"build").install Dir["build/*"]
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

  test do
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1")
  end
end
