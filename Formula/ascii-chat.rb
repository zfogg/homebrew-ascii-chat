class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  url "https://github.com/zfogg/ascii-chat/archive/refs/tags/v0.3.8.tar.gz"
  sha256 "1ef2c1ce6523423272adb3027e8c7c82097102c7c0cbf401de16cb775db0da67"
  license "MIT"
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Submodule dependencies (GitHub archives don't include submodules)
  resource "tomlc17" do
    url "https://github.com/cktan/tomlc17.git",
        revision: "7f3bd33e7356787f665fc7c06ff81d38adb8158c"
  end

  resource "bearssl" do
    url "https://www.bearssl.org/git/BearSSL",
        using: :git,
        revision: "3d9be2f60b7764e46836514bcd6e453abdfa864a"
  end

  resource "libsodium-bcrypt-pbkdf" do
    url "https://github.com/imaami/libsodium-bcrypt-pbkdf.git",
        revision: "47ca0cc6dee63108804a94997ee0835e6000d976"
  end

  resource "uthash" do
    url "https://github.com/troydhanson/uthash.git",
        revision: "af6e637f19c102167fb914b9ebcc171389270b48"
  end

  resource "sokol" do
    url "https://github.com/floooh/sokol.git",
        revision: "4f2386121c103eaf85960322872ea31c9120b85e"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "llvm" => :build
  depends_on "doxygen" => :build
  depends_on "portaudio"
  depends_on "libsodium"
  depends_on "zstd"

  def install
    if build.head?
      # HEAD install: submodules are cloned by git, just init them
      system "git", "submodule", "update", "--init", "--recursive"
    else
      # Tarball install: stage submodule resources into deps/ directory
      %w[tomlc17 bearssl libsodium-bcrypt-pbkdf uthash sokol].each do |dep|
        resource(dep).stage(buildpath/"deps"/dep)
      end

      # Initialize a git repo for version detection
      # The cmake version system uses `git describe --tags` which needs a proper repo
      system "git", "init"
      system "git", "config", "user.email", "brew@localhost"
      system "git", "config", "user.name", "Homebrew"
      system "git", "add", "-A"
      system "git", "commit", "-m", "Initial commit"
      system "git", "tag", "v#{version}"
    end

    # Use Clang from LLVM
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    # Configure with cmake
    system "cmake", "--preset", "release"

    # Build executable, libraries, and docs
    system "cmake", "--build", "build", "--target", "ascii-chat"
    system "cmake", "--build", "build", "--target", "static-lib"
    system "cmake", "--build", "build", "--target", "shared-lib"
    system "cmake", "--build", "build", "--target", "docs"

    # Install using cmake
    system "cmake", "--install", "build"
  end

  test do
    # Test that the binary runs and shows help
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1", 1)
  end
end
