# Builtin command modification

alias update="sudo apt update && sudo apt upgrade -y"
alias cp='cp -i'
alias mkdir='mkdir -p'
alias mv='mv -i'

# aliases for multiple directory listing commands
alias la='ls -Alh'                # show hidden files
alias ls='ls -aFh --color=always' # add colors and file type extensions
alias lx='ls -lXBh'               # sort by extension
alias lk='ls -lSrh'               # sort by size
alias lc='ls -ltcrh'              # sort by change time
alias lu='ls -lturh'              # sort by access time
alias lr='ls -lRh'                # recursive ls
alias lt='ls -ltrh'               # sort by date
alias lm='ls -alh |more'          # pipe through 'more'
alias lw='ls -xAh'                # wide listing format
alias ll='ls -Fls'                # long listing format
alias labc='ls -lap'              # alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # files only
alias ldir="ls -l | egrep '^d'"   # directories only
alias lla='ls -Al'                # List and Hidden Files
alias las='ls -A'                 # Hidden Files
alias lls='ls -l'                 # List


docker-update() {
  sudo find ~/docker -name 'docker-compose.yml' -print0 | while IFS= read -r -d '' filepath; do
    echo "🔄 Updating containers for: $filepath"
    docker compose -f "$filepath" pull
    docker compose -f "$filepath" up -d
  done
}

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# cd into the old directory
alias bd='cd "$OLDPWD"'
alias randomstr="openssl rand -base64"

alias ipv4="ip a | grep -w inet | grep -v inet6"
alias ipv6="ip a | grep -w inet6"

alias gemini="npx https://github.com/google-gemini/gemini-cli"

# External Programs

## aria2c (sudo snap install aria2c)
if command -v aria2c >/dev/null 2>&1; then
  alias download='aria2c --continue=true --max-connection-per-server=16 --split=16 --min-split-size=1M --file-allocation=falloc --human-readable --summary-interval=0'
fi

## bat
if command -v batcat >/dev/null 2>&1; then
  alias bat="batcat"
  alias lb='ls | batcat'
  alias -g -- -h='-h 2>&1 | batcat --language=help --style=plain'
  alias -g -- --help='--help 2>&1 | batcat --language=help --style=plain'
fi


## docker
if command -v docker >/dev/null 2>&1; then
  alias docker-ps='docker ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"'
  alias docker-ps-compact='docker ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"'
  alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '
fi

## ffmpeg
if command -v ffmpeg >/dev/null 2>&1; then
  alias ffmpeg='ffmpeg -hide_banner -loglevel info'
  alias ffprobe='ffprobe -v quiet -print_format json -show_format -show_streams'
  alias ffplay='ffplay -autoexit -hide_banner'
fi
## fzf
if command -v fzf >/dev/null 2>&1; then
  export FZF_DEFAULT_OPTS='--color 16 --layout=reverse --border top'
  alias fzf='fzf --preview "batcat --style=numbers --color=always --line-range=:500 {}"'
fi

## nautilus
if command -v nautilus >/dev/null 2>&1; then
  alias explorer='nautilus --browser'
fi

## ncdu
if command -v ncdu >/dev/null 2>&1; then
  alias ncdu='ncdu --exclude "/home/rpakishore/mnt"'
fi

## speedtest-cli
if command -v speedtest-cli >/dev/null 2>&1; then
  alias speedtest-cli='speedtest-cli --bytes --secure'
fi

## trash
if command -v trash &> /dev/null; then
  alias rm='trash -v'
else
  alias rm='rm -i'  # fallback to interactive remove
fi

## xclip
if command -v xclip >/dev/null 2>&1; then
  alias xcopy='xclip -selection clipboard'
  alias xpaste='xclip -selection clipboard -o'
fi

## yt-dlp
if command -v yt-dlp >/dev/null 2>&1; then
  alias yt-dlp='yt-dlp -S "res,ext:mp4:m4a" --recode-video mp4 --embed-metadata --embed-thumbnail --all-subs -o "%(title)s.%(ext)s" -i'
fi