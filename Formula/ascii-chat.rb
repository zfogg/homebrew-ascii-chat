class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  license "MIT"
  version "0.4.10"

  # Pre-built archive (default) - OS and architecture-specific
  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "fa6f663b96e9f66c6f93ebd2ae878428c7ff8dddfb604a4475d091ff81a624b2"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "fa5c704e934dd0915a7c676cab880a100f92986660ced6439c1c455182c24f5c"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "7d922f3cc7ad37659a5d4da6c0edcc494c8a7740c782875cdfb776ba3c39167b"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "1e7a75931a03578f869c6ae119e1da9390ffd467a4ab2dbfaa941523c55deee0"
    end
  end

  # Build from source with --HEAD
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Build dependencies only needed for --HEAD
  head do
    depends_on "cmake" => :build
    depends_on "doxygen" => :build
    depends_on "libsodium" => :build
    depends_on "lld" => :build
    depends_on "llvm" => :build
    depends_on "mimalloc" => :build
    depends_on "ninja" => :build
    depends_on "portaudio" => :build
    depends_on "zstd" => :build
    depends_on "criterion" => :test
  end

  def install
    if build.head?
      # Build from source
      system "git", "submodule", "update", "--init", "--recursive"

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
    else
      # Install from pre-built tar.gz archive
      # Archive structure: ascii-chat-VERSION-OS-ARCH/{bin,include,lib,share}/
      # Homebrew extracts the archive and if there's a single top-level directory,
      # it automatically enters that directory. Check if we're already in it.
      if Dir.exist?("bin")
        # We're already in the right directory
        bin.install Dir["bin/*"]
        include.install Dir["include/*"] if Dir.exist?("include")
        lib.install Dir["lib/*"] if Dir.exist?("lib")
        # Install share/ which includes completions, docs, and man pages
        share.install Dir["share/*"] if Dir.exist?("share")
        # Explicitly install man pages for proper symlinks
        man1.install Dir["share/man/man1/*"] if Dir.exist?("share/man/man1")
        man3.install Dir["share/man/man3/*"] if Dir.exist?("share/man/man3")
        # Install HTML docs
        doc.install Dir["share/doc/ascii-chat/html"] if Dir.exist?("share/doc/ascii-chat/html")
      else
        # Need to enter the subdirectory
        subdir = Dir["ascii-chat-*"].first
        raise "Could not find ascii-chat directory in #{Dir.pwd}: #{Dir.glob('*')}" unless subdir

        cd subdir do
          bin.install Dir["bin/*"]
          include.install Dir["include/*"] if Dir.exist?("include")
          lib.install Dir["lib/*"] if Dir.exist?("lib")
          # Install share/ which includes completions, docs, and man pages
          share.install Dir["share/*"] if Dir.exist?("share")
          # Explicitly install man pages for proper symlinks
          man1.install Dir["share/man/man1/*"] if Dir.exist?("share/man/man1")
          man3.install Dir["share/man/man3/*"] if Dir.exist?("share/man/man3")
          # Install HTML docs
          doc.install Dir["share/doc/ascii-chat/html"] if Dir.exist?("share/doc/ascii-chat/html")
        end
      end
    end
  end

  test do
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1", 1)
  end
end
