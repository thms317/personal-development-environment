# Personal Development Environment

![macOS](https://img.shields.io/badge/os-macOS-lightgrey?logo=apple)[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
[![semantic-release](https://github.com/thms317/personal-development-environment/actions/workflows/semantic-release.yml/badge.svg)](https://github.com/thms317/personal-development-environment/actions/workflows/semantic-release.yml)

Guidelines for setting up my personal development environment.

## Getting Started

### Essential tools

1. Visual Studio Code
   - include `extensions.json`
   - include `settings.json`
2. iTerm2
3. Brew
   - do not forget to add to `PATH`
4. Oh My Zsh
   - include `git`
   - include `zsh-autosuggestions`
   - include `zsh-syntax-highlighting`
   - install [`mcfly`](https://github.com/cantino/mcfly)
5. Display Link Manager
6. CopyLess 2
7. noTunes

### Nice to have

Usually these tools will automatically be installed when you start developing.

1. [`.vscode`](https://github.com/thms317/personal-development-environment/.vscode) settings and extensions
2. [`Poetry`](https://python-poetry.org/)
3. [`uv`](https://docs.astral.sh/uv/)
4. [`Databricks CLI`](https://docs.databricks.com/dev-tools/cli/index.html)
   - configure `.databrickscfg`
5. [`JetBrains Mono`](https://www.jetbrains.com/lp/mono/)
6. [`Pydantic`](https://docs.pydantic.dev)
7. [`Polars`](https://pola.rs/)
8. [`Loguru`](https://loguru.readthedocs.io/en/stable/)

### Install Personal Scripts

Place the following scripts in the `"$HOME/scripts/` folder.

- `pr_generator.sh`
- `cleanup_branches.sh`
- `angular_commit_generator.sh`

Make these scripts executable by running:

```bash
chmod +x $HOME/scripts/pr_generator.sh
chmod +x $HOME/scripts/cleanup_branches.sh
chmod +x $HOME/scripts/angular_commit_generator.sh
```

## Shell Configuration

### `.zshrc`

```bash
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set oh-my-zsh theme
ZSH_THEME="agnoster"

# Configure oh-my-zsh plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Initialize oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Configure prompt (minimal)
prompt_context() {}

# Configure prompt (with random emojis)
prompt_context() {
  emojis=("⚡️" "🔥" "💀" "👑" "😎" "🐸" "🐵" "🦄" "🌈" "🍻" "🚀" "💡" "🎉" "🔑" "🇹🇭" "🚦" "🌙")
  RAND_EMOJI_N=$(( $RANDOM % ${#emojis[@]} + 1))
  prompt_segment black default "${emojis[$RAND_EMOJI_N]} "
}

# Configure McFly
eval "$(mcfly init zsh)"
```

### `.zprofile`

```bash
# XF0RC3R
alias dc="docker-compose"
alias up="dc up"
alias down="dc down"
alias tf="terraform"
alias gl="git log --graph --all --decorate"

# Thomas
alias pr="$HOME/scripts/pr_generator.sh"
alias clean="$HOME/scripts/cleanup_branches.sh"
alias cm="$HOME/scripts/angular_commit_generator.sh"
```

## Things I Built

- [RevoData Asset Bundle Templates](https://github.com/revodatanl/revo-asset-bundle-templates)
- [spotify](https://github.com/thms317/spotify)
- [blocq-ehbo](https://github.com/thms317/blocq-ehbo)
- [scifi-boekenclub](https://github.com/thms317/scifi-boekenclub)

## Things I have Written

- [Mastering Terraform in 10 days](https://www.linkedin.com/pulse/mastering-terraform-10-days-thomas-brouwer/)
