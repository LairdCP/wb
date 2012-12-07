TARGETDIR=$1

# Set root password to ’root’. Password generated with
# mkpasswd, from the ’whois’ package in Debian/Ubuntu.
## sed -i ’s%^root::%root:8kfIfYHmcyQEE:%’ $TARGETDIR/etc/shadow

# Application/log file mount point
#mkdir -p $TARGETDIR/applog
## grep -q "^/dev/mtdblock7" $TARGETDIR/etc/fstab || \
## echo "/dev/mtdblock7\t\t/applog\tjffs2\tdefaults\t\t0\t0" \
## >> $TARGETDIR/etc/fstab

# Copy the rootfs additions
tar c --exclude=.svn -C board/sdc/wb40n/rootfs-additions/ . | tar x -C $TARGETDIR/

# copy my RSA public key to device
install -d -m 700 $TARGETDIR/root/.ssh
install -m 600 $HOME/.ssh/id_rsa.pub $TARGETDIR/root/.ssh/authorized_keys

# delete the default ssh init file
rm -f $TARGETDIR/etc/init.d/S50sshd
