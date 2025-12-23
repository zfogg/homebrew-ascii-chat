class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  version "0.4.12"
  license "MIT"

  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "libsodium" => :build
  depends_on "lld" => :build
  depends_on "llvm" => :build
  depends_on "mimalloc" => :build
  depends_on "ninja" => :build
  depends_on "opus" => :build
  depends_on "portaudio" => :build
  depends_on "speexdsp" => :build
  depends_on "zstd" => :build
  depends_on "criterion" => :test

  on_macos do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-arm64.tar.gz"
      sha256 "8585d5902c4d0131c719b566ffb6a14594ebbadbe42eea148c27920f515d9503"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-macOS-amd64.tar.gz"
      sha256 "f0ec8f5e75062ad730255f2880dce2056e7e0bbe41669efb604c421b7b22279d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-arm64.tar.gz"
      sha256 "93834470fda9eb849efaa1db0ed60fd68fec377b097a169827445aa08834cc3e"
    end

    on_intel do
      url "https://github.com/zfogg/ascii-chat/releases/download/v#{version}/ascii-chat-#{version}-Linux-amd64.tar.gz"
      sha256 "7c262c787b7b5ab5dee26d167ff594ff071df6308e2609b0d46751c22ce1d247"
    end
  end

  def install
    if build.head?
      system "git", "submodule", "update", "--init", "--recursive"

      ENV["CC"] = Formula["llvm"].opt_bin/"clang"
      ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

      llvm_bin = Formula["llvm"].opt_bin
      system "cmake", "-B", "build", "-S", ".", "-G", "Ninja",
             "-DCMAKE_BUILD_TYPE=Release",
             "-DCMAKE_INSTALL_PREFIX=#{prefix}",
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
    if (prefix/"build").exist?
      cd prefix/"build" do
        system "ctest", "--output-on-failure", "--verbose"
      end
    end
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1", 1)
  end
end
