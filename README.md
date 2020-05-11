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
 * added more friendly help
 * script became more talkative
 * Added lots of CLI options (see -h option)
 * if you use a single partition, you can use hard links instead of copy (use -l, --link options)
 * removed APPS: cat more less nano (now, you can add it by CLI option -a )

# make_chroot_jail

So, why I made another script?
I would like to make chroot environment for SSH-server with configuration options
```Match User <username>
    ChrootDirectory /path/to/chroot
```
If you use this option in the /etc/ssh/sshd_config, SSHD reads user environment from the system `/etc/passwd` (not from `/path/to/chroot/etc/passwd`).
And then chrooted user to the `/path/to/chroot` with $HOME and $SHELL from system's `/etc/passwd`.

New script create all nessesory environment into the `/path/to/chroot` in minimal configuration.
By default, it allows only ssh with `/bin/bash /bin/sh /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /usr/bin/ssh /usr/bin/scp ` and sftp.
If you need more application, you can add by CLI options.
- creates user
- copy or create hard link for all application and libraries
- don't use PAM in the Jail



#Help-messages:
```
./make_chroot_jail.sh -h

USAGE: ./make_chroot_jail.sh < -u username [options]... | --update [options]... | -h >

          -u,   --user      username    Set the name of new or exist user
                --update                Update files (not user) inside of jail
          -h,   --help                  Show this message

          Options:
          -a    --apps     "/path/app1 /p/to/app2"  Add your apps to avaliable inside of Jail.
                                                      Space-separated quoted list of paths
          -c    --config    /path/to/sshd_config    Set path to sshd_config. ($SSHD_CONFIG)
                                                      Default:/etc/ssh/sshd_config
          -j,   --jail      /path/to/jail           Set the root of jail.
                                                      Default:/home/jail
          -l,   --link                              Set hard link mode.
          -n,   --nopam                             Do not copy PAM libs.
          -s,   --shell     /path/to/chroot-shell   Set name of shell for chrooted user.
                                                      Default:/bin/chroot-shell

-------------------------------------------------------------

Create new chrooted account or
add existing User to chroot-jail:
-> ./make_chroot_jail.sh -u username

or specify the chroot-shell file, path where the jail should be located and [--link] option:
-> ./make_chroot_jail.sh -u username -s /path/to/chroot-shell -j /path/to/jail --link
-------------------------------------------------------------

You can specify [--link] option, if the files in the chroot are
on the same file system as the original files.
It creates hard links instead of copy files.
By default, script copies files.
-------------------------------------------------------------

You can specify [--nopam] option, in case you don't want to use the PAM inside the jail
-------------------------------------------------------------

or update files in the chroot-jail:
-> ./make_chroot_jail.sh --update -s /path/to/chroot-shell -j /path/to/jail --link
-------------------------------------------------------------

You can include your application to the chroot by modification of $APPS variable
-------------------------------------------------------------

-------------------------------------------------------------

To uninstall:
 # userdel $USER
 # rm -rf /home/jail
 (this deletes all Users' files!)
 # rm -f /bin/chroot-shell
 manually delete the User's line from /etc/sudoers

```
