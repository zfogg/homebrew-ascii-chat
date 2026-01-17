# ascii-chat Homebrew Tap

Official Homebrew tap for [ascii-chat](https://github.com/zfogg/ascii-chat) - real-time terminal-based video chat with ASCII art conversion.

## Installation

```bash
# Add the tap and install
brew install zfogg/ascii-chat/ascii-chat

# Or add the tap first
brew tap zfogg/ascii-chat
brew install ascii-chat
```

### Build from Source

```bash
brew install --HEAD zfogg/ascii-chat/ascii-chat
```

## What's Included

- `ascii-chat` binary
- Man page (`man ascii-chat`)
- Shell completions (bash, zsh, fish)
- Development library (`libasciichat.a`, `libasciichat.dylib`)
- Header files (`$(brew --prefix)/include/ascii-chat/`)
- pkg-config file (`ascii-chat.pc`)
- CMake config files

## Development

Link against libasciichat in your project:

```bash
# Using pkg-config
cc $(pkg-config --cflags --libs ascii-chat) myapp.c -o myapp

# Using CMake
find_package(ascii-chat REQUIRED)
target_link_libraries(myapp ascii-chat::ascii-chat)
```

## Documentation

- **Repository**: [github.com/zfogg/ascii-chat](https://github.com/zfogg/ascii-chat)
- **API Docs**: [zfogg.github.io/ascii-chat](https://zfogg.github.io/ascii-chat/)
