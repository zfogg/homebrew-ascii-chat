# ascii-chat Homebrew Tap

Official Homebrew tap for [ascii-chat](https://github.com/zfogg/ascii-chat) - real-time terminal-based video chat with ASCII art conversion.

## Available Formulas

### ascii-chat (Runtime)
The main ascii-chat binary for video chat in your terminal.

```bash
brew install zfogg/ascii-chat/ascii-chat
```

**Includes:**
- `ascii-chat` binary
- Man page (`man ascii-chat`)
- Shell completions (bash, zsh, fish)

### libasciichat (Development)
Development libraries, headers, and documentation for building applications with ascii-chat.

```bash
brew install zfogg/ascii-chat/libasciichat
```

**Includes:**
- Static library (`libasciichat.a`)
- Shared library (`libasciichat.dylib`)
- Header files (`/usr/local/include/ascii-chat/`)
- pkg-config file (`ascii-chat.pc`)
- CMake config files
- API documentation (Doxygen HTML)
- Library man pages (man3)

## Installation

### Quick Start

```bash
# Add the tap
brew tap zfogg/ascii-chat

# Install runtime binary
brew install ascii-chat

# Optional: Install development libraries
brew install libasciichat
```

### One-Line Install

```bash
# Runtime only
brew install zfogg/ascii-chat/ascii-chat

# Runtime + development
brew install zfogg/ascii-chat/ascii-chat zfogg/ascii-chat/libasciichat
```

### Using Brewfile

Add to your `Brewfile`:

```ruby
tap "zfogg/ascii-chat"
brew "ascii-chat"           # Runtime binary
brew "libasciichat"         # Development libraries (optional)
```

Then run: `brew bundle`

## Documentation

- **ascii-chat**: [GitHub Repository](https://github.com/zfogg/ascii-chat)
- **API Documentation**: [zfogg.github.io/ascii-chat](https://zfogg.github.io/ascii-chat/)
- **Homebrew**: `brew help`, `man brew`, or [Homebrew's documentation](https://docs.brew.sh)
