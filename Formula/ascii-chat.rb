class AsciiChat < Formula
  desc "Video chat in your terminal"
  homepage "https://ascii-chat.com"
  version "0.16.30"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.16.30/ascii-chat-0.16.30-macOS-arm64.tar.gz"
    sha256 "ffe4126170824cefaa9eb553b56a7896c16fe8af42ce066e1e408d43c534f0b3"
  else
    url "https://github.com/zfogg/ascii-chat/releases/download/v0.16.30/ascii-chat-0.16.30-macOS-amd64.tar.gz"
    sha256 "6fad6eedda696bf6c99585343a00cf4d568afe4c34723e912399c2fd9339b222"
  end

  depends_on "gnupg"
  depends_on "openssh"
  depends_on "yt-dlp"

  def install
    bin.install "bin/ascii-chat"
    if File.exist?("share/man/man1/ascii-chat.1")
      man1.install "share/man/man1/ascii-chat.1"
    end
    if File.exist?("share/bash-completion/completions/ascii-chat")
      bash_completion.install "share/bash-completion/completions/ascii-chat"
    end
    if File.exist?("share/zsh/site-functions/_ascii-chat")
      zsh_completion.install "share/zsh/site-functions/_ascii-chat"
    end
    if File.exist?("share/fish/vendor_completions.d/ascii-chat.fish")
      fish_completion.install "share/fish/vendor_completions.d/ascii-chat.fish"
    end
  end

  test do
    assert_match "ascii-chat", shell_output("#{bin}/ascii-chat --help 2>&1")
  end
end
