# mac-dev-setup

One script to bootstrap a fresh Mac into a full-featured developer terminal: modern CLI tools, Ghostty + Starship prompt, git with delta, cloud tooling (AWS, Azure, Terraform, Kubernetes), Python/Databricks, and the Claude Code CLI.

Safe to re-run — it skips anything already installed.

## Quick start

```bash
git clone https://github.com/marinsalinas/mac-dev-setup.git
cd mac-dev-setup
./setup.sh
```

## Options

| Flag | Description |
| --- | --- |
| `--force` | Overwrite existing config files without prompting |
| `--theme "<name>"` | Set the Ghostty theme (default: `Material Dark`) |
| `--minimal` | Skip cloud, Python, and AI tools for a faster install |

Example:

```bash
./setup.sh --force --theme "Dracula"
./setup.sh --minimal
```

## What it installs

### Terminal & shell

- [Homebrew](https://brew.sh/) — package manager
- [Ghostty](https://ghostty.org/) — terminal emulator
- [FiraCode Nerd Font](https://www.nerdfonts.com/)
- [Starship](https://starship.rs/) — prompt
- `zsh-autosuggestions`, `zsh-syntax-highlighting`
- [tmux](https://github.com/tmux/tmux)

### Modern CLI replacements

- [fzf](https://github.com/junegunn/fzf) — fuzzy finder
- [zoxide](https://github.com/ajeetdsouza/zoxide) — smarter `cd`
- [eza](https://github.com/eza-community/eza) — modern `ls`
- [bat](https://github.com/sharkdp/bat) — modern `cat`
- [ripgrep](https://github.com/BurntSushi/ripgrep) — modern `grep`
- [fd](https://github.com/sharkdp/fd) — modern `find`
- [delta](https://github.com/dandavison/delta) — better git diffs
- `jq`, `yq`, `tldr`, `httpie`, `direnv`

### Development

- git (latest), [gh](https://cli.github.com/), [lazygit](https://github.com/jesseduffield/lazygit)
- [neovim](https://neovim.io/), `pre-commit`

### Cloud & infrastructure

- AWS CLI, Azure CLI
- Terraform (via [HashiCorp's official tap](https://github.com/hashicorp/homebrew-tap))
- `kubectl`, `helm`, [k9s](https://k9scli.io/)

### Python / Databricks

- `pyenv`, `pipx`, `databricks-cli`, `argcomplete`

### AI tools

- [Claude Code CLI](https://claude.com/claude-code) (`npm install -g @anthropic-ai/claude-code`)

## What it configures

- `~/.zshrc` — aliases, functions (fzf pickers for git branches, k8s pods, AWS profiles, Azure subs), history settings
- `~/.config/starship.toml` — prompt with git, Python, Terraform, Kubernetes, AWS, Azure segments
- `~/.tmux.conf` — `Ctrl+a` prefix, mouse support, vim-style pane navigation
- Ghostty config — font, theme, keybindings
- Git global config — delta pager, side-by-side diffs, sensible defaults

Existing config files are backed up (e.g. `~/.zshrc.backup.YYYYMMDDHHMMSS`) before being replaced.

## Requirements

- **macOS 14 (Sonoma) or later** — officially supported. macOS 13 (Ventura) may work on a best-effort basis (minimum for Ghostty, and Homebrew's unsupported tier), but isn't tested.
- Apple Silicon or Intel — both are handled (universal binaries where available)
- An internet connection
- Admin password for Xcode Command Line Tools (prompted on first run)

## License

[MIT](LICENSE)
