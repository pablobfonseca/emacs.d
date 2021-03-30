export PATH="/usr/local/sbin:$PATH"

export HISTSIZE=20000
export SAVEHIST=20000

export DOTFILES=$HOME/.dotfiles

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

export GOPATH=$HOME/code/go-workspace
export GOROOT=/usr/local/opt/go/libexec
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

# Auto-suggestions
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -U compinit
compinit

if [ -n "$HTTP_TOOLKIT_ACTIVE" ]; then
    # When HTTP Toolkit is active, we inject various overrides into PATH
    export PATH="/Users/pablofonseca/.local/share/httptoolkit-server/client/1.0.2/overrides/path:$PATH"

    if command -v winpty >/dev/null 2>&1; then
        # Work around for winpty's hijacking of certain commands
        alias php=php
        alias node=node
    fi
fi

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -s $HOME/.nvm/nvm.sh ]] && . $HOME/.nvm/nvm.sh

function search_route {
  bin/rails routes | rg $1
}

function bundle_search() {
    pattern="$1"; shift
    ag $pattern $(bundle show --paths "$@")
}

function take {
    mkdir $1
    cd $1
}

rvmlist() {
    local rb
    rb=$((echo system; rvm list | grep ruby | cut -c 4-) |
             awk '{print $1}' |
             fzf -l 30 +m --reverse) && rvm use $rb
}

nvmlist() {
    local njs
    njs=$((nvm ls --no-colors --no-alias | cut -c 8-) | awk '{print $1}' | fzf -l 30 +m --reverse) && nvm use $njs
}

alias path="echo $PATH | tr -s ':' '\n'"
alias reload!='source ~/.zshrc'
alias brew_update='brew update && brew upgrade && brew cleanup'

eval "$(starship init zsh)"
