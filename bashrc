# ~/.bashrc — UbuntuBox colour theme
# Two-line prompt with cyan brackets, green user, blue host, yellow path

# ── Don't run if not interactive ─────────────────────────────────────────────
case $- in
    *i*) ;;
    *) return;;
esac

# ── History ───────────────────────────────────────────────────────────────────
HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
shopt -s checkwinsize

# ── Colour prompt ─────────────────────────────────────────────────────────────
# Palette (256-colour escape codes)
_RESET='\[\e[0m\]'
_CYAN='\[\e[38;5;87m\]'          # bright cyan  — brackets
_GREEN='\[\e[38;5;83m\]'         # bright green — username
_BLUE='\[\e[38;5;75m\]'          # sky blue     — hostname
_YELLOW='\[\e[38;5;220m\]'       # yellow       — path
_RED='\[\e[38;5;203m\]'          # red          — root indicator
_DIM='\[\e[2m\]'                 # dimmed

# Top line:   ┌──[user@host]──[~/path]
# Bottom line: └──$   (or └──# for root)
if [ "$(id -u)" -eq 0 ]; then
    _USER_COLOR="${_RED}"
    _PROMPT_CHAR='#'
else
    _USER_COLOR="${_GREEN}"
    _PROMPT_CHAR='$'
fi

PS1="${_CYAN}┌──[${_USER_COLOR}\u${_CYAN}@${_BLUE}\h${_CYAN}]──[${_YELLOW}\w${_CYAN}]\n└──${_PROMPT_CHAR}${_RESET} "

# ── ls colours ────────────────────────────────────────────────────────────────
# dircolors entry: bold cyan dirs, bold green executables, red hidden files,
# yellow archives, magenta images
export LS_COLORS='rs=0:di=01;38;5;75:ln=01;38;5;51:mh=00:pi=40;38;5;11:so=01;38;5;13:do=01;38;5;13:bd=40;38;5;11:cd=40;38;5;11:or=40;38;5;9:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;38;5;83:*.tar=38;5;220:*.tgz=38;5;220:*.gz=38;5;220:*.zip=38;5;220:*.7z=38;5;220:*.jpg=38;5;213:*.jpeg=38;5;213:*.png=38;5;213:*.gif=38;5;213:*.mp4=38;5;213:*.mp3=38;5;213:*.py=38;5;214:*.sh=38;5;155:*.js=38;5;227:*.json=38;5;185:*.md=38;5;159:*.txt=38;5;252:*.log=38;5;240:*.conf=38;5;187:*.yml=38;5;187:*.yaml=38;5;187'

alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'

# ── grep colours ──────────────────────────────────────────────────────────────
export GREP_COLORS='ms=01;38;5;203:mc=01;38;5;203:sl=:cx=:fn=38;5;75:ln=38;5;83:bn=38;5;220:se=38;5;240'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ── diff colours ─────────────────────────────────────────────────────────────
alias diff='diff --color=auto'

# ── man page colours (cyan/yellow highlights) ────────────────────────────────
export LESS_TERMCAP_mb=$'\e[1;38;5;87m'    # begin blinking
export LESS_TERMCAP_md=$'\e[1;38;5;75m'    # begin bold (section headers)
export LESS_TERMCAP_me=$'\e[0m'            # end mode
export LESS_TERMCAP_se=$'\e[0m'            # end standout
export LESS_TERMCAP_so=$'\e[38;5;220;48;5;235m'  # standout (search highlight)
export LESS_TERMCAP_ue=$'\e[0m'            # end underline
export LESS_TERMCAP_us=$'\e[4;38;5;83m'   # begin underline (command names)
export MANPAGER='less -R'

# ── Useful aliases ────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias mkdir='mkdir -pv'
alias cp='cp -iv'
alias mv='mv -iv'
alias df='df -h'
alias du='du -sh'
alias free='free -h'
alias top='top -c'
alias cat='cat'
alias cls='clear'
alias h='history'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me && echo'

# ── Git shortcuts ─────────────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --color'
alias gd='git diff --color'

# ── Python shortcuts ─────────────────────────────────────────────────────────
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'

# ── Coloured GCC warnings and errors ─────────────────────────────────────────
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# ── Path ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Welcome message + neofetch ───────────────────────────────────────────────
sleep 0.3 && neofetch
