# .profile

export PATH=/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin

umask 022

alias which='fe'

# ls variants
alias ll='ls -l'
alias la='ls -lA'
alias logs='ls -l /var/log/'

# ps variants
alias psu='ps -o pid,stat,args |grep -vE "[ ]\[.*\]|[ ]ps\ "'
alias psf='pstree -p'

