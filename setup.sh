#!/bin/bash
#
# ============================================
# Mac Terminal Setup Script
# ============================================
#
# This script sets up a complete terminal environment on a fresh Mac.
# Run this when you get a new computer or want to standardize your setup.
#
# Safe to run multiple times - it will skip already installed components.
#
# What it installs:
#   Terminal & Shell:
#     - Homebrew (package manager)
#     - Ghostty (terminal emulator)
#     - FiraCode Nerd Font
#     - Starship (prompt)
#     - zsh-autosuggestions (command suggestions)
#     - zsh-syntax-highlighting (syntax colors)
#     - tmux (terminal multiplexer)
#
#   Modern CLI Tools:
#     - fzf (fuzzy finder)
#     - zoxide (smarter cd)
#     - eza (modern ls)
#     - bat (modern cat)
#     - ripgrep (modern grep)
#     - fd (modern find)
#     - delta (better git diffs)
#     - jq/yq (JSON/YAML processors)
#     - tldr (simplified man pages)
#     - httpie (modern curl)
#     - direnv (per-directory env vars)
#
#   Development Tools:
#     - git (latest version)
#     - gh (GitHub CLI)
#     - lazygit (terminal git UI)
#     - neovim (modern vim)
#     - pre-commit (git hooks)
#
#   Cloud & Infrastructure:
#     - awscli (AWS CLI)
#     - azure-cli (Azure CLI)
#     - terraform (IaC)
#     - kubectl (Kubernetes CLI)
#     - helm (Kubernetes package manager)
#     - k9s (Kubernetes TUI)
#
#   Python/Databricks:
#     - pyenv (Python version manager)
#     - pipx (isolated Python tools)
#     - databricks-cli (via pipx)
#
#   AI Tools:
#     - node (required for Claude Code CLI)
#     - Claude Code CLI (@anthropic-ai/claude-code)
#
# Usage:
#   chmod +x setup-mac-terminal.sh
#   ./setup-mac-terminal.sh
#
# Options:
#   --force           Overwrite existing config files without asking
#   --theme <name>    Set Ghostty theme (default: "Material Dark")
#   --minimal         Skip cloud and heavy tools (faster install)
#

set -e

# Parse arguments
FORCE=false
MINIMAL=false
GHOSTTY_THEME="Material Dark"

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=true
            shift
            ;;
        --theme)
            GHOSTTY_THEME="$2"
            shift 2
            ;;
        --minimal)
            MINIMAL=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo ""
echo "🚀 Mac Terminal Setup"
echo "====================="
echo ""

# ============================================
# Helper function to check if a brew package is installed
# ============================================
brew_installed() {
    brew list "$1" &>/dev/null
}

# ============================================
# Helper function to check if a cask is installed
# ============================================
cask_installed() {
    brew list --cask "$1" &>/dev/null 2>&1 || \
    [[ -d "/Applications/$2.app" ]] 2>/dev/null
}

# ============================================
# Helper function to prompt for overwrite
# ============================================
should_overwrite() {
    local file=$1
    if [[ -f "$file" ]]; then
        if [[ "$FORCE" == true ]]; then
            return 0
        fi
        echo ""
        read -p "   ⚠️  $file already exists. Overwrite? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        else
            return 1
        fi
    fi
    return 0
}

# ============================================
# 1. Install Xcode Command Line Tools
# ============================================
if ! xcode-select -p &> /dev/null; then
    echo "📦 Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "   Please complete the Xcode installation and re-run this script."
    exit 1
else
    echo "✅ Xcode Command Line Tools"
fi

# ============================================
# 2. Install Homebrew
# ============================================
if ! command -v brew &> /dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo ""
        echo "   Adding Homebrew to PATH (Apple Silicon)..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew"
fi

# Make sure brew is in PATH for this session
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
fi

# ============================================
# 3. Install Core CLI Tools
# ============================================
echo ""
echo "📦 Checking core CLI tools..."

# Core tools everyone needs
CORE_TOOLS=(
    starship
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    zoxide
    eza
    bat
    ripgrep       # rg - faster grep
    fd            # faster find
    git-delta     # better git diffs
    jq            # JSON processor
    yq            # YAML processor
    tldr          # simplified man pages
    httpie        # modern curl
    direnv        # per-directory env vars
    git           # latest git
    gh            # GitHub CLI
    lazygit       # terminal git UI
    neovim        # modern vim
    tmux          # terminal multiplexer
    pre-commit    # git hooks framework
)

TOOLS_TO_INSTALL=()

for tool in "${CORE_TOOLS[@]}"; do
    if brew_installed "$tool"; then
        echo "   ✅ $tool"
    else
        echo "   ⏳ $tool (will install)"
        TOOLS_TO_INSTALL+=("$tool")
    fi
done

if [[ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]]; then
    echo ""
    echo "   Installing: ${TOOLS_TO_INSTALL[*]}"
    brew install "${TOOLS_TO_INSTALL[@]}"
fi

# ============================================
# 3b. Install Cloud & DevOps Tools (skip with --minimal)
# ============================================
if [[ "$MINIMAL" == false ]]; then
    echo ""
    echo "☁️  Checking cloud & DevOps tools..."

    # Terraform was removed from homebrew-core after HashiCorp's BUSL
    # relicense (Aug 2023). Install from the official HashiCorp tap.
    brew tap hashicorp/tap &>/dev/null

    CLOUD_TOOLS=(
        awscli                      # AWS CLI
        azure-cli                   # Azure CLI
        hashicorp/tap/terraform     # Infrastructure as Code
        kubectl                     # Kubernetes CLI
        helm                        # Kubernetes package manager
        k9s                         # Kubernetes TUI
    )
    
    CLOUD_TO_INSTALL=()
    
    for tool in "${CLOUD_TOOLS[@]}"; do
        if brew_installed "$tool"; then
            echo "   ✅ $tool"
        else
            echo "   ⏳ $tool (will install)"
            CLOUD_TO_INSTALL+=("$tool")
        fi
    done
    
    if [[ ${#CLOUD_TO_INSTALL[@]} -gt 0 ]]; then
        echo ""
        echo "   Installing: ${CLOUD_TO_INSTALL[*]}"
        brew install "${CLOUD_TO_INSTALL[@]}"
    fi
fi

# ============================================
# 3c. Install Python Tools (skip with --minimal)
# ============================================
if [[ "$MINIMAL" == false ]]; then
    echo ""
    echo "🐍 Checking Python tools..."
    
    # Install pyenv for Python version management
    if brew_installed "pyenv"; then
        echo "   ✅ pyenv"
    else
        echo "   ⏳ pyenv (will install)"
        brew install pyenv
    fi
    
    # Install pipx for isolated Python tools
    if brew_installed "pipx"; then
        echo "   ✅ pipx"
    else
        echo "   ⏳ pipx (will install)"
        brew install pipx
        pipx ensurepath
    fi
    
    # Install argcomplete for pipx shell completions
    if pipx list 2>/dev/null | grep -q "argcomplete"; then
        echo "   ✅ argcomplete"
    else
        echo "   ⏳ argcomplete (will install via pipx)"
        pipx install argcomplete
    fi
    
    # Install Databricks CLI via pipx
    if pipx list 2>/dev/null | grep -q "databricks-cli"; then
        echo "   ✅ databricks-cli"
    else
        echo "   ⏳ databricks-cli (will install via pipx)"
        pipx install databricks-cli
    fi
fi

# ============================================
# 3d. Install AI Tools (skip with --minimal)
# ============================================
if [[ "$MINIMAL" == false ]]; then
    echo ""
    echo "🤖 Checking AI tools..."

    # Node.js is required for Claude Code CLI (installed via npm)
    if brew_installed "node"; then
        echo "   ✅ node"
    else
        echo "   ⏳ node (will install)"
        brew install node
    fi

    # Claude Code CLI
    if command -v claude &> /dev/null; then
        echo "   ✅ claude (Claude Code CLI)"
    else
        echo "   ⏳ claude (will install via npm)"
        npm install -g @anthropic-ai/claude-code
    fi
fi

# ============================================
# 4. Install Nerd Font
# ============================================
echo ""
if cask_installed "font-fira-code-nerd-font" ""; then
    # Check if font is actually installed in the system
    if ls ~/Library/Fonts/*FiraCode*Nerd* &>/dev/null 2>&1 || \
       ls /Library/Fonts/*FiraCode*Nerd* &>/dev/null 2>&1; then
        echo "✅ FiraCode Nerd Font"
    else
        echo "📦 Installing FiraCode Nerd Font..."
        brew install --cask font-fira-code-nerd-font
    fi
else
    echo "📦 Installing FiraCode Nerd Font..."
    brew install --cask font-fira-code-nerd-font
fi

# ============================================
# 5. Install Ghostty Terminal
# ============================================
echo ""
if cask_installed "ghostty" "Ghostty"; then
    echo "✅ Ghostty"
else
    echo "👻 Installing Ghostty..."
    brew install --cask ghostty
fi

# ============================================
# 6. Configure Zsh (~/.zshrc)
# ============================================
echo ""
echo "⚙️  Configuring Zsh..."

if should_overwrite ~/.zshrc; then
    # Backup existing .zshrc
    if [[ -f ~/.zshrc ]]; then
        BACKUP_FILE=~/.zshrc.backup.$(date +%Y%m%d%H%M%S)
        cp ~/.zshrc "$BACKUP_FILE"
        echo "   Backed up to $BACKUP_FILE"
    fi

    cat << 'EOF' > ~/.zshrc
# ============================================
# Zsh Configuration
# Generated by setup-mac-terminal.sh
# ============================================

# Homebrew (Apple Silicon)
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Autosuggestions (gray ghost text from history)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (colors commands as you type)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Better tab completions
autoload -Uz compinit && compinit

# fzf keybindings and fuzzy completion (Ctrl+R for history)
source <(fzf --zsh)

# Zoxide (smarter cd - use 'z' to jump to directories)
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"

# direnv (per-directory environment variables)
eval "$(direnv hook zsh)"

# pipx binaries path (must be before pyenv)
export PATH="$HOME/.local/bin:$PATH"

# pyenv (Python version management)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &> /dev/null && eval "$(pyenv init -)"

# pipx completions (if argcomplete is installed)
if command -v register-python-argcomplete &> /dev/null; then
    eval "$(register-python-argcomplete pipx)"
fi

# ============================================
# Aliases - Modern CLI Replacements
# ============================================
alias ls="eza --icons"
alias ll="eza --icons -la"
alias la="eza --icons -a"
alias lt="eza --icons --tree"
alias tree="eza --icons --tree"
alias cat="bat"
alias grep="rg"
alias find="fd"
alias vim="nvim"
alias vi="nvim"

# ============================================
# Aliases - Git Shortcuts
# ============================================
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gcm="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch"
alias gd="git diff"
alias gds="git diff --staged"
alias gl="git log --oneline --graph --decorate -15"
alias gla="git log --oneline --graph --decorate --all"
alias lg="lazygit"

# ============================================
# Aliases - Kubernetes
# ============================================
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kgn="kubectl get namespaces"
alias kctx="kubectl config current-context"
alias kns="kubectl config set-context --current --namespace"
alias kdesc="kubectl describe"
alias klogs="kubectl logs"
alias kexec="kubectl exec -it"

# ============================================
# Aliases - AWS
# ============================================
alias awswho="aws sts get-caller-identity"
alias awsprofiles="aws configure list-profiles"
alias s3ls="aws s3 ls"
alias s3cp="aws s3 cp"

# ============================================
# Aliases - Azure
# ============================================
alias azwho="az account show"
alias azsubs="az account list --output table"
alias azset="az account set --subscription"
alias azgroups="az group list --output table"
alias azvms="az vm list --output table"

# ============================================
# Aliases - Terraform
# ============================================
alias tf="terraform"
alias tfi="terraform init"
alias tfp="terraform plan"
alias tfa="terraform apply"
alias tfd="terraform destroy"
alias tfv="terraform validate"
alias tff="terraform fmt"

# ============================================
# Aliases - Docker
# ============================================
alias d="docker"
alias dc="docker compose"
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias dex="docker exec -it"
alias dlogs="docker logs"
alias dprune="docker system prune -af"

# ============================================
# Aliases - Databricks
# ============================================
alias db="databricks"
alias dbfs="databricks fs"
alias dbjobs="databricks jobs"
alias dbclusters="databricks clusters"

# ============================================
# Aliases - General Shortcuts
# ============================================
alias c="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias mkdir="mkdir -p"
alias reload="source ~/.zshrc"
alias zshrc="$EDITOR ~/.zshrc"
alias hosts="sudo $EDITOR /etc/hosts"
alias myip="curl -s ifconfig.me"
alias localip="ipconfig getifaddr en0"
alias ports="lsof -i -P -n | grep LISTEN"
alias weather="curl wttr.in"
alias help="tldr"

# ============================================
# Functions
# ============================================

# Create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Quick find file by name
ff() {
    fd --type f --hidden --follow --exclude .git "$1"
}

# Quick find directory by name
fdir() {
    fd --type d --hidden --follow --exclude .git "$1"
}

# Search file contents
fif() {
    rg --files-with-matches --no-messages "$1" | fzf --preview "bat --color=always {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || bat --color=always {}"
}

# Git branch selector with fzf
fbr() {
    git branch --all | grep -v HEAD | fzf --preview "git log --oneline --graph --date=short --color=always {}" | sed "s/.* //" | sed "s#remotes/origin/##"
}

# Docker container selector
dselect() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | fzf --header-lines=1 | awk '{print $1}'
}

# Kubernetes pod selector
kpod() {
    kubectl get pods | fzf --header-lines=1 | awk '{print $1}'
}

# AWS profile switcher
awsprofile() {
    export AWS_PROFILE=$(aws configure list-profiles | fzf --prompt="Select AWS Profile: ")
    echo "Switched to AWS profile: $AWS_PROFILE"
}

# Azure subscription switcher
azsub() {
    local sub=$(az account list --query "[].{name:name, id:id}" -o tsv | fzf --prompt="Select Azure Subscription: " | awk '{print $NF}')
    az account set --subscription "$sub"
    echo "Switched to Azure subscription: $(az account show --query name -o tsv)"
}

# Kubernetes namespace switcher
knsswitch() {
    local ns=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | fzf --prompt="Select Namespace: ")
    kubectl config set-context --current --namespace="$ns"
    echo "Switched to namespace: $ns"
}

# Kubernetes context switcher
kctxswitch() {
    local ctx=$(kubectl config get-contexts -o name | fzf --prompt="Select Context: ")
    kubectl config use-context "$ctx"
    echo "Switched to context: $ctx"
}

# Quick JSON pretty print
json() {
    if [ -t 0 ]; then
        cat "$1" | jq .
    else
        jq .
    fi
}

# Quick YAML to JSON
y2j() {
    yq -o=json "$@"
}

# Quick JSON to YAML  
j2y() {
    yq -P "$@"
}

# Databricks workspace info
dbwho() {
    databricks current-user me
}

# Start a quick HTTP server
serve() {
    local port="${1:-8000}"
    echo "Serving on http://localhost:$port"
    python3 -m http.server "$port"
}

# ============================================
# History Settings
# ============================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY

# ============================================
# Environment Variables
# ============================================
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Colorful man pages with bat
export BAT_THEME="Dracula"

# FZF defaults
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview-window=right:60%'
EOF

    echo "   ✅ Created ~/.zshrc"
else
    echo "   ⏭️  Skipped ~/.zshrc (keeping existing)"
fi

# ============================================
# 7. Configure Starship (~/.config/starship.toml)
# ============================================
echo ""
echo "⭐ Configuring Starship..."

mkdir -p ~/.config

if should_overwrite ~/.config/starship.toml; then
    cat << 'EOF' > ~/.config/starship.toml
# Starship Prompt Configuration
# https://starship.rs/config/

add_newline = true

# Prompt format - organize left to right
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$terraform\
$kubernetes\
$docker_context\
$aws\
$azure\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vicmd_symbol = "[❮](bold blue)"

[directory]
truncation_length = 4
truncate_to_repo = true
style = "bold cyan"

[git_branch]
symbol = " "
format = "[$symbol$branch(:$remote_branch)]($style) "
style = "bold purple"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
staged = '[++\($count\)](green)'
modified = '[~\($count\)](yellow)'
deleted = '[x\($count\)](red)'
ahead = '[⇡\($count\)](bold blue)'
behind = '[⇣\($count\)](bold purple)'
diverged = '[⇕⇡$ahead_count⇣$behind_count](bold red)'

[python]
symbol = "🐍 "
format = "[$symbol$version( \\($virtualenv\\))]($style) "
detect_extensions = ["py"]
detect_files = ["pyproject.toml", "requirements.txt", ".python-version", "Pipfile"]
style = "yellow"

[nodejs]
symbol = "⬢ "
format = "[$symbol$version]($style) "
style = "green"

[terraform]
symbol = "󱁢 "
format = "[$symbol$workspace]($style) "
style = "bold 105"
detect_extensions = ["tf", "tfplan", "tfstate"]
detect_files = [".terraform"]
detect_folders = [".terraform"]

[kubernetes]
symbol = "☸ "
format = "[$symbol$context( \\($namespace\\))]($style) "
style = "bold blue"
disabled = false
detect_extensions = []
detect_files = ["Dockerfile", "k8s", "kubernetes", "helm"]
detect_folders = ["k8s", "kubernetes", "helm", "charts"]

[docker_context]
symbol = "🐳 "
format = "[$symbol$context]($style) "
style = "blue"
only_with_files = true
detect_files = ["docker-compose.yml", "docker-compose.yaml", "Dockerfile"]

[aws]
symbol = "☁️ "
format = "[$symbol($profile )(\\($region\\) )]($style)"
style = "bold yellow"
disabled = false

[aws.region_aliases]
us-east-1 = "use1"
us-west-2 = "usw2"
eu-west-1 = "euw1"

[azure]
symbol = "󰠅 "
format = "[$symbol($subscription)]($style) "
style = "bold blue"
disabled = false

[cmd_duration]
min_time = 2000
format = "⏳ [$duration]($style) "
style = "bold yellow"
show_milliseconds = false

[battery]
full_symbol = "🔋 "
charging_symbol = "⚡ "
discharging_symbol = "⚠️ "
disabled = true

[[battery.display]]
threshold = 20
style = "bold red"

[time]
disabled = true
format = "[🕒 $time]($style) "
time_format = "%H:%M"

[container]
format = "[$symbol$name]($style) "
symbol = "⬢ "
style = "bold red"

# Spark/Databricks detection (via Python files)
[custom.databricks]
command = "echo '󰣀'"
when = "test -f databricks.yml || test -d .databricks"
format = "[$output]($style) "
style = "bold red"
EOF

    echo "   ✅ Created ~/.config/starship.toml"
else
    echo "   ⏭️  Skipped ~/.config/starship.toml (keeping existing)"
fi

# ============================================
# 8. Configure Git
# ============================================
echo ""
echo "🔧 Configuring Git..."

# Set up delta as the default pager
git config --global core.pager "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.light false
git config --global delta.line-numbers true
git config --global delta.side-by-side true
git config --global merge.conflictstyle "diff3"
git config --global diff.colorMoved "default"

# Useful git defaults
git config --global init.defaultBranch "main"
git config --global pull.rebase false
git config --global push.autoSetupRemote true
git config --global rerere.enabled true
git config --global column.ui auto
git config --global branch.sort -committerdate

echo "   ✅ Git configured with delta and sensible defaults"

# ============================================
# 9. Configure Ghostty
# ============================================
echo ""
echo "👻 Configuring Ghostty..."

# Ghostty config location based on OS
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS uses Application Support
    GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
else
    # Linux uses XDG
    GHOSTTY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
fi

mkdir -p "$GHOSTTY_CONFIG_DIR"

if should_overwrite "$GHOSTTY_CONFIG_DIR/config"; then
    cat << EOF > "$GHOSTTY_CONFIG_DIR/config"
# Font settings
font-family = "FiraCode Nerd Font"
font-size = 14
font-feature = calt
font-feature = liga

# Theme
theme = "$GHOSTTY_THEME"

# Window settings
window-padding-x = 10
window-padding-y = 10
window-decoration = true
macos-titlebar-style = hidden

# Cursor
cursor-style = block
cursor-style-blink = true

# Shell integration
shell-integration = zsh
shell-integration-features = cursor,sudo,title

# Scrollback
scrollback-limit = 100000

# Copy/paste
clipboard-read = allow
clipboard-write = allow
copy-on-select = true

# Keybindings (macOS-friendly)
keybind = super+t=new_tab
keybind = super+w=close_surface
keybind = super+shift+enter=new_split:right
keybind = super+shift+minus=new_split:down
keybind = super+left_bracket=goto_split:previous
keybind = super+right_bracket=goto_split:next
keybind = super+d=new_split:right
keybind = super+shift+d=new_split:down
EOF

    echo "   ✅ Created $GHOSTTY_CONFIG_DIR/config"
else
    echo "   ⏭️  Skipped Ghostty config (keeping existing)"
fi

# ============================================
# 10. Configure tmux
# ============================================
echo ""
echo "📺 Configuring tmux..."

if should_overwrite ~/.tmux.conf; then
    cat << 'EOF' > ~/.tmux.conf
# ============================================
# tmux Configuration
# Generated by setup-mac-terminal.sh
# ============================================

# Use Ctrl+a as prefix (easier than Ctrl+b)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Enable 256 colors and true color
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"

# Increase history limit
set -g history-limit 50000

# Reduce escape time (for vim)
set -sg escape-time 10

# Split panes with | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Navigate panes with vim keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Resize panes with Shift+vim keys
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# Reload config with r
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Status bar styling
set -g status-position top
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left '#[fg=#89b4fa,bold] #S '
set -g status-right '#[fg=#a6adc8] %Y-%m-%d %H:%M '
set -g status-left-length 50
set -g status-right-length 50

# Window styling
setw -g window-status-format ' #I:#W '
setw -g window-status-current-format '#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W '

# Pane borders
set -g pane-border-style 'fg=#313244'
set -g pane-active-border-style 'fg=#89b4fa'
EOF

    echo "   ✅ Created ~/.tmux.conf"
else
    echo "   ⏭️  Skipped ~/.tmux.conf (keeping existing)"
fi

# ============================================
# Done!
# ============================================
echo ""
echo "============================================"
echo "✅ Setup complete!"
echo "============================================"
echo ""
echo "What's installed:"
echo ""
echo "  Terminal & Shell:"
echo "    • Ghostty (terminal) with $GHOSTTY_THEME theme"
echo "    • FiraCode Nerd Font"
echo "    • Starship (prompt)"
echo "    • zsh-autosuggestions & syntax-highlighting"
echo "    • tmux (terminal multiplexer)"
echo ""
echo "  Modern CLI Replacements:"
echo "    • fzf (Ctrl+R for fuzzy history)"
echo "    • zoxide (use 'z' instead of 'cd')"
echo "    • eza (modern 'ls' → ls, ll, la, lt)"
echo "    • bat (modern 'cat')"
echo "    • ripgrep (modern 'grep' → rg)"
echo "    • fd (modern 'find')"
echo "    • delta (better git diffs)"
echo "    • jq/yq (JSON/YAML processors)"
echo "    • httpie (modern curl)"
echo ""
echo "  Development:"
echo "    • Git (latest) with delta integration"
echo "    • gh (GitHub CLI)"
echo "    • lazygit (terminal git UI → lg)"
echo "    • neovim (→ vim, vi)"
echo "    • pre-commit"
echo "    • direnv"
echo ""
if [[ "$MINIMAL" == false ]]; then
echo "  Cloud & Infrastructure:"
echo "    • awscli (AWS CLI)"
echo "    • azure-cli (Azure CLI)"
echo "    • terraform (→ tf)"
echo "    • kubectl (→ k) & helm"
echo "    • k9s (Kubernetes TUI)"
echo ""
echo "  Python/Databricks:"
echo "    • pyenv (Python version manager)"
echo "    • pipx (isolated Python tools)"
echo "    • databricks-cli (→ db)"
echo ""
echo "  AI Tools:"
echo "    • node (for Claude Code CLI)"
echo "    • Claude Code CLI (→ claude)"
echo ""
fi
echo "Next steps:"
echo "  1. Close this terminal"
echo "  2. Open Ghostty"
echo "  3. Run: source ~/.zshrc"
echo ""
echo "Quick tips:"
echo "  • 'lg' opens lazygit"
echo "  • 'k' is kubectl, 'tf' is terraform"
echo "  • 'z <partial-path>' jumps to directories"
echo "  • Ctrl+R for fuzzy history search"
echo "  • 'awsprofile' to switch AWS profiles"
echo "  • 'kpod' to fuzzy-select Kubernetes pods"
echo ""
echo "Options:"
echo "  • --force to overwrite configs without prompting"
echo "  • --theme \"Dracula\" for a different theme"
echo "  • --minimal to skip cloud/DevOps tools"
echo ""