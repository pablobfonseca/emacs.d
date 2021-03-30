export GOPATH=$HOME/code/go-workspace
export GOROOT=/usr/local/opt/go/libexec
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

# export FZF_DEFAULT_OPTS='--height=50% --min-height=15 --preview="bat --style=numbers --color=always {} | head -500" --preview-window=right:60%:wrap'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'


export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_COMPLETE=1

# Auto-suggestions
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

autoload -U compinit
compinit

source ~/.zplug/init.zsh

zplug "b4b4r07/enhancd"

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load --verbose

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
             fzf) && rvm use $rb
}

nvmlist() {
    local njs
    njs=$((nvm ls --no-colors --no-alias | cut -c 8-) | awk '{print $1}' | fzf) && nvm use $njs
}

alias path="echo $PATH | tr -s ':' '\n'"
alias reload!='source ~/.zshrc'
alias brew_update='brew update && brew upgrade && brew cleanup'
alias code="cd ~/code && cd"

eval "$(starship init zsh)"
