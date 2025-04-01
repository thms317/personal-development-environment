# Personal Development Environment

![macOS](https://img.shields.io/badge/os-macOS-lightgrey?logo=apple)
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
[![semantic-release](https://github.com/thms317/personal-development-environment/actions/workflows/semantic-release.yml/badge.svg)](https://github.com/thms317/personal-development-environment/actions/workflows/semantic-release.yml)

Guidelines for setting up my personal development environment.

## Getting Started

### System settings

- **Key repeat rate**: 'fast'
- **Delay until repeat**: 'short'
- **Hot Corners**: set the top right corner to 'Desktop'

### Essential tools

1. [Cursor](https://www.cursor.com/) (formerly known as [Visual Studio Code](https://code.visualstudio.com/))
   - include `extensions.json`
   - include `settings.json`
2. Configure Terminal
   - [iTerm2](https://iterm2.com/)
   - [Oh My Zsh](https://ohmyz.sh/)
      - include [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#homebrew) plugin

         ```bash
         git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
         ```

      - include [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md) plugin

         ```bash
         git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
         ```

   - [McFly](https://github.com/cantino/mcfly)
   - [Homebrew](https://brew.sh/)
   - [JetBrains Mono](https://www.jetbrains.com/lp/mono/)
      - set as default font in iTerm2
      - set as default font in VSCode
3. [DisplayLink](https://www.synaptics.com/products/displaylink-graphics/downloads/macos)
4. [CopyLess 2](https://copyless.net/)
5. [noTunes](https://formulae.brew.sh/cask/notunes)

Add the relevant tools to login items.

## Shell Configuration

Example configurations of [`.zshrc`](config/.zshrc) and [`.zprofile`](config/.zprofile) can be found in the [`config`](config) folder.

### Install Personal Scripts

Use `brew` to install the following tools:

```bash
brew install jq
brew install tree
```

Place the following scripts in the `"$HOME/scripts/` folder.

- `pr_generator.sh`
- `cleanup_branches.sh`
- `angular_commit_generator.sh`
- `ttree.sh`

Make these scripts executable by running:

```bash
chmod +x $HOME/scripts/pr_generator.sh
chmod +x $HOME/scripts/cleanup_branches.sh
chmod +x $HOME/scripts/angular_commit_generator.sh
chmod +x $HOME/scripts/ttree.sh
```

Add the following aliases to your `~/.zprofile` file:

```bash
alias pr="$HOME/scripts/pr_generator.sh"
alias clean="$HOME/scripts/cleanup_branches.sh"
alias cm="$HOME/scripts/angular_commit_generator.sh"
alias ttree="$HOME/scripts/ttree.sh"
```

### Nice to have

Usually these tools will automatically be installed when you start developing.

1. [`.vscode`](https://github.com/thms317/personal-development-environment/.vscode) settings and extensions
2. [`uv`](https://docs.astral.sh/uv/)
3. [`Poetry`](https://python-poetry.org/)
4. [`Databricks CLI`](https://docs.databricks.com/dev-tools/cli/index.html)
5. [`Pydantic`](https://docs.pydantic.dev)
6. [`Polars`](https://pola.rs/)
7. [`Loguru`](https://loguru.readthedocs.io/en/stable/)

## Things I Built

- [RevoData Asset Bundle Templates](https://github.com/revodatanl/revo-asset-bundle-templates)
- [spotify](https://github.com/thms317/spotify)
- [blocq-ehbo](https://github.com/thms317/blocq-ehbo)
- [scifi-boekenclub](https://github.com/thms317/scifi-boekenclub)

## Things I have Written

- [Mastering Terraform in 10 days](https://www.linkedin.com/pulse/mastering-terraform-10-days-thomas-brouwer/)
