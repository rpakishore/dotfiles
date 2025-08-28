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

# alias to cleanup unused docker containers, images, networks, and volumes

alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '


docker-update() {
  sudo find ~/docker -name 'docker-compose.yml' -print0 | while IFS= read -r -d '' filepath; do
    echo "🔄 Updating containers for: $filepath"
    docker compose -f "$filepath" pull
    docker compose -f "$filepath" up -d
  done
}

alias docker-ps='docker ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}\t{{.Status}}"'
alias docker-ps-compact='docker ps --all --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"'

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# cd into the old directory
alias bd='cd "$OLDPWD"'

# External Programs
alias bat="batcat"
alias explorer="nautilus --browser"
alias speedtest-cli='speedtest-cli --bytes --secure'
if command -v trash &> /dev/null; then
    alias rm='trash -v'
else
    alias rm='rm -i'  # fallback to interactive remove
fi

alias randomstr="openssl rand -base64"


alias ipv4="ip a | grep -w inet | grep -v inet6"
alias ipv6="ip a | grep -w inet6"

alias gemini="npx https://github.com/google-gemini/gemini-cli"

alias download='aria2c --continue=true --max-connection-per-server=16 --split=16 --min-split-size=1M --file-allocation=falloc --human-readable --summary-interval=0'
