# .profile

export PATH=/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin

umask 022

# ls variants
alias ll='ls -l'
alias la='ls -lA'
alias logs='ls -l /var/log/'

# ps variants
alias psu='ps |grep -v "[ ]\[.*\]"'
alias psf='pstree -p'
 
