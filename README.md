# make_chroot_jail
Script to easily setup a chroot jail for ssh / scp / sftp with Linux

The original script was taken from  
http://www.fuschlberger.net/programs/ssh-scp-sftp-chroot-jail/  
You'll find nice explanation and usage instructions there.  
More specific examples are on the net, search for "make_chroot_jail".

Second commit has changes needed for Ubuntu 12.04, and was originally published at
http://www.devcu.com/forums/topic/560-chrootjail-users-for-sshscp-ubuntu-1204/ (!!! link has broken at start of May 2020)

Finally, current version made the script non-interactive, better suitable for automated operation:
 * create user without a password
 * if the user exists and jailed then do nothing
 * if the user exists then jail her
 * do not create shell if already exists

Additional changes:
 * tested on Ubuntu 8.04 to 14.04
 * added APPS: cat more less nano
 * copied /lib/terminfo

Update 2020-05-11:
 * tested on Debian 9
 * added more frendly help
 * script became more talkative
 * added lots of CLI options (see -h option)
 * if you use single partition, you can use hard links instead of copy (use -l, --link options)
 * fixed some problems with "&>/dev/null" (line 585)

