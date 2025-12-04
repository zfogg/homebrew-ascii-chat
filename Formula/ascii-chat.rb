class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  license "MIT"
  version "0.3.57"

  # Pre-built archive (default) - OS and architecture-specific
  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "81de500f8912e04a4e782aba1eaeefd808d6fc8e0f0dfc90adbe8aaecb7159a2"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "32f59a2ff8333cd7a8a271c0e423ee60062f1e992883b4a21231b86a3e376566"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "c5876198b8c31e193b0484350a43aed73f0b78d0b576f7b1d8a1673d3cb033e7"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "da31360e36b8ef224e3c93f25f0daa4ea93b95934d86cea29e82641fa8c0cc35"
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
