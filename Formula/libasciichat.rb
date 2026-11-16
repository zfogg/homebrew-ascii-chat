class Libasciichat < Formula
  desc "Reusable C library for ascii-chat applications"
  homepage "https://ascii-chat.com"
  version "0.16.30"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.16.30/libasciichat-0.16.30-macOS-arm64.tar.gz"
    sha256 "dc8238cdd393e2510ba8eda5748131831e9f98e934a9b0e45766cf68ad9561e8"
  else
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.16.30/libasciichat-0.16.30-macOS-amd64.tar.gz"
    sha256 "8ecf8e52c990b93e3390175eeb784ec4cf9f9ab53af04632597ad408105f3ea0"
  end

  depends_on "ffmpeg"
  depends_on "fftw"
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "libsodium"
  depends_on "libde265"
  depends_on "libpng"
  depends_on "libwebsockets"
  depends_on "mimalloc"
  depends_on "miniupnpc"
  depends_on "nghttp2"
  depends_on "nghttp3"
  depends_on "ngtcp2"
  depends_on "openssl@3"
  depends_on "opus"
  depends_on "pcre2"
  depends_on "portaudio"
  depends_on "sqlite"
  depends_on "x265"
  depends_on "yyjson"
  depends_on "zstd"

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_path_exists include/"ascii-chat/api.h"
    assert_path_exists lib/"pkgconfig/libasciichat.pc"
    assert_path_exists lib/"cmake/ascii-chat/ascii-chat-config.cmake"
  end
end
