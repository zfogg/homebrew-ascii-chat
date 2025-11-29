class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://github.com/zfogg/ascii-chat"
  url "https://github.com/zfogg/ascii-chat/archive/refs/tags/v0.3.7.tar.gz"
  sha256 "b650d6050fcefd31292d46ea9781d23894667c279d7fbf86c70e02f8ce2f486e"
  license "MIT"
  head "https://github.com/zfogg/ascii-chat.git", branch: "master"

  # Submodule dependencies (GitHub archives don't include submodules)
  resource "tomlc17" do
    url "https://github.com/cktan/tomlc17.git",
        revision: "7f3bd33e7356787f665fc7c06ff81d38adb8158c"
  end

  resource "bearssl" do
    url "https://www.bearssl.org/git/BearSSL",
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
  depends_on "portaudio" => :build
  depends_on "libsodium" => :build
  depends_on "zstd" => :build
  depends_on "mimalloc" => :build

  def install
    # Use Clang from LLVM
    ENV["CC"] = Formula["llvm"].opt_bin/"clang"
    ENV["CXX"] = Formula["llvm"].opt_bin/"clang++"

    # Choose preset based on platform
    if OS.linux?
      # Linux uses musl for static builds
      system "cmake", "--preset", "release-musl", "-B", "build"
    else
      # macOS uses standard release preset
      system "cmake", "--preset", "release", "-B", "build"
    end

    # Build documentation, libraries, and executables
    system "cmake", "--build", "build", "--target", "docs"
    system "cmake", "--build", "build", "--target", "static-lib"
    system "cmake", "--build", "build", "--target", "shared-lib"
    system "cmake", "--build", "build", "--target", "ascii-chat"

    # Install to Homebrew prefix
    system "cmake", "--install", "build", "--prefix", prefix
  end

  test do
    # Test that the binary runs and shows help
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1", 1)
  end
end
