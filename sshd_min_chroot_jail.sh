#!/bin/sh
#
# (c) Copyright by Wolfgang Fuschlberger
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    ( http://www.fsf.org/licenses/gpl.txt )
#####################################################################

# first Release: 2004-07-30
RELEASE="2020-05-07"
#
# The original script was taken from
#   http://www.fuschlberger.net/programs/ssh-scp-sftp-chroot-jail/
# And then forked from 
#   https://github.com/pmenhart/make_chroot_jail
# And then modified by 
#   pmenhart/Benbria
#   http://www.devcu.com/forums/topic/560-chrootjail-users-for-sshscp-ubuntu-1204/
#####################################################################

#
# Features:
# - creates user
# - copy or create hard link for all application and libraries
# - don't use PAM in the Jail
# - update files in the Jail
#####################################################################

# 
# CHANGELOG
# Modified by Maksim Kramarenko 
#   http://www.k-max.name/
# - tested on Debian and Ubuntu (Multiarch-compatable)
# - added more friendly help and script became more talkative
# - Added lots of CLI options (see -h option)
# - if you use a single partition, you can use hard links instead of copy (use -l, --link options)
# 
#####################################################################

# path to sshd's config file: needed for automatic detection of the locaten of
# the sftp-server binary
SSHD_CONFIG="/etc/ssh/sshd_config"
APPS=""
action=add
SHELL=/bin/bash
JAILPATH=/chroot
LINK=cp
PAM=nocopy

# Show HELP message
usage () {
  echo
  echo "USAGE: $0 < -u username [options]... | --update [options]... | -h >"
  echo 
  echo "          -u,   --user      username    Set the name of new or exist user"
  echo "                --update                Update files (not user) inside of jail"
  echo "          -h,   --help                  Show this message"
  echo 
  echo "          Options:"
  echo "          -a    --apps     \"/path/app1 /p/to/app2\"  Add your apps to be avaliable inside of Jail."
  echo "                                                      Space-separated quoted list of paths"
  echo "          -c    --config    /path/to/sshd_config    Set path to sshd_config. (\$SSHD_CONFIG)"
  echo "                                                      Default:/etc/ssh/sshd_config"
  echo "          -j,   --jail      /path/to/jail           Set the root of jail."
  echo "                                                      Default:/chroot"
  echo "          -l,   --link                              Set hard link mode."
  echo "          -p,   --pam                               Provide PAM libs in the Jail."
  echo "                                                      Default: PAM will not be provided"
  echo "          -s,   --shell     /path/to/chroot-shell   Set shell for Jail'ed user. "
  echo "                                                      Default:/bin/bash"
  echo
  echo "-------------------------------------------------------------"
  echo
  echo "Create new chrooted account or"
  echo "add existing User to chroot-jail:"
  echo "-> $0 -u username"
  echo
  echo "or specify the chroot-shell file, path where the jail should be located:"
  echo "-> $0 -u username -s /path/to/chroot-shell -j /path/to/jail"
  echo "-------------------------------------------------------------"
  echo
  echo "You can specify [--link] option, if files in the chroot are "
  echo "on the same file system as the original files."
  echo "It creates hard links instead of copy files."
  echo "By default, script copies files."
  echo "-------------------------------------------------------------"
  echo
  echo "You can specify [--pam] option, in case you want to use the PAM inside the jail."
  echo "-------------------------------------------------------------"
  echo
  echo "or update files in the chroot-jail:"
  echo "-> $0 --update -s /path/to/chroot-shell -j /path/to/jail"
  echo "-------------------------------------------------------------"
  echo
  echo "You can include your application to the chroot by modification of \$APPS variable"
  echo "-------------------------------------------------------------"
  echo
  echo "To uninstall:"
  echo " # userdel \$USER"
  echo " # rm -rf /chroot"
  echo " (this deletes all Users' files!)"
}

copy_or_link () {
    if [ $LINK = "ln" ]; then
        if [ "$1" = "-p" ]; then shift ; fi
        # prevent create Link for recurcive copy
        if [ "$1" != "-r" ]; then
            for dst in $@; do :; done # get the latest CLI argument = destination
            until [ "$1" = "$dst" ]; do
              if [ -d $dst ]; then
#               echo "current link to DIR will be ln -v --force $( readlink -nf $1 ) $dst/$( basename -z $1 )"
                ln --force $( readlink -nf $1 ) $dst/$( basename -z $1 )
                shift
              else
                ln --force $( readlink -nf $1 ) $dst
                shift
              fi
            done 
        else
#          echo "Start Copy files Recucively"
          /bin/cp $*
        fi
    else
        #echo "Start Copy files"
        /bin/cp $*
    fi
    
} # This replace of cp command to make hard links of just copy

##### Main

if [ $# -eq 0 ] ; then
  echo
  echo "USAGE: $0 < -u username [options]... | --update [options]... | -h >"
  echo
  exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        -a | --apps )         shift
                              APPS="$1"
                              ;;
        --update )         		action=update
                              ;;

        -u | -user )    			shift
                              CHROOT_USERNAME=$1
							              	;;
        
        -s | --shell )    	  shift
                              SHELL=$1
                              ;;
        
        -j | --jail )    	    shift
                              JAILPATH=$1
                              ;;
        
        -l | --link )    	    LINK=ln
                              ;;
        
        -n| --pam )           PAM=copy
                              ;;
        
        -c | --config )       shift
                              SSHD_CONFIG=$1
                              ;;
        
        -h | -? | --help )    usage
                              exit
                              ;;
        
        * )                   usage
                              exit 1
    esac
    shift
done

echo
if [ $action = "update" ]; then
  echo "!!! You are going to <$action> all files (hard links) inside of Jail <$JAILPATH>."
else
  echo "!!! You are going to <$action> the user <$CHROOT_USERNAME> into the Jail <$JAILPATH>."
fi
echo "Shell for Jail'ed user is <$SHELL>. Files will be <${LINK}>'ed."
echo "Config of SSHd is <$SSHD_CONFIG>. PAM modules will be <$PAM>'ed."
echo "List of additional application into the Jail are <$APPS>."
echo "
-----------------------------
Is it correct?"
read -p "(yes/no) -> " CORRECT
if [ "$CORRECT" != "yes" ]; then
  echo "
Not entered yes. Exiting...."
  exit 1
fi

if [ -z "$PATH" ] ; then 
  PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin
fi

echo
echo $0 Release: $RELEASE
echo

if [ "$(whoami &2>/dev/null)" != "root" ] && [ "$(id -un &2>/dev/null)" != "root" ] ; then
  echo "Error: You must be root to run this script."
  exit 1
fi

# Check existence of necessary files
echo "Checking distribution... "
if [ -f /etc/debian_version ];
  then echo -n "  Supported Distribution found:"
       echo "  System is running Debian Linux"
       DISTRO=DEBIAN;
elif [ -f /etc/SuSE-release ];
  then echo -n "  Supported Distribution found^"
       echo "  System is running SuSE Linux"
       DISTRO=SUSE;
elif [ -f /etc/fedora-release ];
  then echo -n "  Supported Distribution found:"
       echo "  System is running Fedora Linux"
       DISTRO=FEDORA;
elif [ -f /etc/redhat-release ];
  then echo -n "  Supported Distribution found:"
       echo "  System is running Red Hat Linux"
       DISTRO=REDHAT;
else echo -e "  failed...........\nThis script works best on Debian, Red Hat, Fedora and SuSE Linux!\nLet's try it nevertheless....\nIf some program files cannot be found adjust the respective path in line 98\n"
#exit 1
fi

# Specify the apps you want to copy to the jail
if [ "$DISTRO" = SUSE ]; then
  APPS="${APPS} /bin/bash /usr/bin/dircolors /usr/bin/groups /usr/bin/id /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/ssh /usr/bin/scp"
elif [ "$DISTRO" = FEDORA ]; then
  APPS="${APPS} /bin/bash /usr/bin/dircolors /usr/bin/groups /usr/bin/id /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/ssh /usr/bin/scp"
elif [ "$DISTRO" = REDHAT ]; then
  APPS="${APPS} /bin/bash /usr/bin/dircolors /usr/bin/groups /usr/bin/id /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/ssh /usr/bin/scp"
elif [ "$DISTRO" = DEBIAN ]; then
  APPS="${APPS} /bin/bash /usr/bin/dircolors /usr/bin/groups /usr/bin/id /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/ssh /usr/bin/scp"
else
  APPS="${APPS} /bin/bash /usr/bin/dircolors /usr/bin/groups /usr/bin/id /bin/cp /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/ssh /usr/bin/scp"
fi

# Check existence of necessary files
echo -n "Checking for which... "
if ( test -f /usr/bin/which ) || ( test -f /bin/which ) || ( test -f /sbin/which ) || ( test -f /usr/sbin/which );
  then echo "  OK";
  else echo "  failed

Please install which-binary!
You can try to find it by:
yum whatprovides */which                # on RHEL
apt-file search /which | grep /which$   # on Deb-based
zypper search --provides which          # on SUSE
"
exit 1
fi

echo -n "Checking for dirname..."
if [ `which dirname` ]; then
  echo "  OK";
else 
  echo "  failed

dirname not found!
Please install dirname-binary (to be found eg in the package coreutils)!
You can try to find it by:
yum whatprovides */dirname                  # on RHEL
apt-file search /dirname | grep /dirname$   # on Deb-based
zypper search --provides dirname            # on SUSE
"
exit 1
fi

echo -n "Checking for readlink..."
if [ `which readlink` ]; then
  echo "  OK";
else 
  echo "  failed

readlink not found!
Please install readlink-binary (to be found eg in the package coreutils)!
You can try to find it by:
yum whatprovides */readlink                  # on RHEL
apt-file search /readlink | grep /readlink$  # on Deb-based
zypper search --provides readlink            # on SUSE
"
exit 1
fi

echo -n "Checking for awk..."
if [ `which awk` ]; then
  echo "  OK
";
else 
  echo "  failed

awk not found!
Please install (g)awk-package/binary! (named like gawk)
You can try to find it by:
yum whatprovides */awk              # on RHEL
apt-file search awk | grep awk$     # on Deb-based
zypper search --provides awk        # on SUSE
"
exit 1
fi

# get location of sftp-server binary from /etc/ssh/sshd_config
# check for existence of /etc/ssh/sshd_config and for
# (uncommented) line with sftp-server filename. If neither exists, just skip
# this step and continue without sftp-server
#
if [ ! -f ${SSHD_CONFIG} ]
then
   echo "File ${SSHD_CONFIG} not found."
   echo "Not checking for path to sftp-server."
   echo "Please adjust the global \$SSHD_CONFIG variable"
else
  if !(grep -v "^#" ${SSHD_CONFIG} | grep -i sftp-server &> /dev/null); then
    echo "Obviously no external sftp-server is running on this system.
";
  else SFTP_SERVER=$(grep -v "^#" ${SSHD_CONFIG} | grep -i sftp-server | awk  '{ print $3}')
  fi
fi

APPS="$APPS $SFTP_SERVER"

# Check if user already exists and ask for confirmation
# we have to trust that root knows what she is doing when saying 'yes'
if ( test "$CHROOT_USERNAME" != "" && id $CHROOT_USERNAME > /dev/null 2>&1 ) ; then {
  echo -n "User $CHROOT_USERNAME exists."
#TODO: add to CLI interactive mode
#echo "-----------------------------
#User $CHROOT_USERNAME exists. 

#Are you sure you want to modify the users home directory and lock him into the
#chroot directory?
#Are you REALLY sure?
#Say only yes if you absolutely know what you are doing!"
#  read -p "(yes/no) -> " MODIFYUSER
#  if [ "$MODIFYUSER" != "yes" ]; then
#    echo "
#Not entered yes. Exiting...."
  #if [ -d $JAILPATH/home/$CHROOT_USERNAME ] ; then # original string
  if [ -d /home/$CHROOT_USERNAME ] && [ -d $JAILPATH/home/$CHROOT_USERNAME ] ; then
    echo "Already jailed. Exiting...."
    exit 1
  fi
  echo "Adding the user to jail."
  MODIFYUSER="yes"
  }
else
  CREATEUSER="yes"
fi

# make common jail for everybody if inexistent
if [ ! -d ${JAILPATH} ] ; then
  mkdir -p ${JAILPATH}
  echo "Creating ${JAILPATH}"
fi
cd ${JAILPATH}

# Create directories in jail that do not exist yet
JAILDIRS="dev etc etc/pam.d bin home sbin usr usr/bin usr/lib"
for directory in $JAILDIRS ; do
  if [ ! -d "$JAILPATH/$directory" ] ; then
    mkdir $JAILPATH/"$directory"
    echo "Creating $JAILPATH/$directory"
  fi
done
echo

# Creating necessary devices
[ -r $JAILPATH/dev/urandom ] || mknod $JAILPATH/dev/urandom       c 1 9
[ -r $JAILPATH/dev/null ]    || mknod -m 666 $JAILPATH/dev/null   c 1 3
[ -r $JAILPATH/dev/zero ]    || mknod -m 666 $JAILPATH/dev/zero   c 1 5
[ -r $JAILPATH/dev/tty ]     || mknod -m 666 $JAILPATH/dev/tty    c 5 0 

# if we only want to update the files in the jail
# skip the creation of the new account
if [ $action != "update" ]; then

  # Define HomeDir for simple referencing
  HOMEDIR="/home/$CHROOT_USERNAME"

  # Create new account, setting $SHELL to the above created script and
  # $HOME to $JAILPATH/home/*
  if [ "$CREATEUSER" != "yes" ] ; then
    echo "  Not creating new User account
  Modifying User \"$CHROOT_USERNAME\" 
  Copying files in $CHROOT_USERNAME's \$HOME to \"$HOMEDIR\"
    "
    usermod -d "$HOMEDIR" -m -s "$SHELL" $CHROOT_USERNAME && chmod 700 "$HOMEDIR"
    if [ ! -d "${JAILPATH}${HOMEDIR}" ] ; then # Make copy of HOMEDIR in the Jail
      mkdir ${JAILPATH}${HOMEDIR}
      cp -p -r $HOMEDIR ${JAILPATH}${HOMEDIR}
    fi
  fi # endif usermod

  if [ "$CREATEUSER" = "yes" ] ; then {
    echo "Adding User \"$CHROOT_USERNAME\" to system (no password)"
    useradd -m -d "$HOMEDIR" -s "$SHELL" $CHROOT_USERNAME && chmod 700 "$HOMEDIR"
    cp -p -r $HOMEDIR ${JAILPATH}${HOMEDIR}

    # Enter password for new account - TODO for interactive mode
    if !(passwd $CHROOT_USERNAME);
       then echo "Passwords are probably not the same, try again."
          exit 1;
        fi
        echo
  }
  fi # endif useradd

  # Add users to etc/passwd
  #
  # check if file exists (ie we are not called for the first time)
  # if yes skip root's entry and do not overwrite the file
  if [ ! -f etc/passwd ] ; then
    grep /etc/passwd -e "^root" > ${JAILPATH}/etc/passwd
  fi
  if [ ! -f etc/group ] ; then
    grep /etc/group -e "^root" > ${JAILPATH}/etc/group
  # add the group for all users to etc/group (otherwise there is a nasty error
  # message and probably because of that changing directories doesn't work with
  # winSCP)
    grep /etc/group -e "^users" >> ${JAILPATH}/etc/group
  fi

  # grep the username which was given to us from /etc/passwd and add it
  # to ./etc/passwd replacing the $HOME with the directory as it will then 
  # appear in the jail
  echo "Adding User $CHROOT_USERNAME to jail"
  grep -e "^$CHROOT_USERNAME:" /etc/passwd | \
   sed -e "s#$JAILPATH##"      \
       -e "s#$SHELL#/bin/bash#"  >> ${JAILPATH}/etc/passwd

  # if the system uses one account/one group we write the
  # account's group to etc/group
  grep -e "^$CHROOT_USERNAME:" /etc/group >> ${JAILPATH}/etc/group

  ## write the user's line from /etc/shadow to /home/jail/etc/shadow
  #grep -e "^$CHROOT_USERNAME:" /etc/shadow >> ${JAILPATH}/etc/shadow
  #chmod 600 ${JAILPATH}/etc/shadow

  echo "
Please, add the next lines to the end of <${SSHD_CONFIG}> 
-------------------------------------

Match User $CHROOT_USERNAME
  ChrootDirectory ${JAILPATH}

------------------------------------
"
  
  # endif for =! update
fi

# Copy the apps and the related libs
echo "Copying necessary library-files to jail (may take some time)"

# The original code worked fine on RedHat 7.3, but did not on FC3.
# On FC3, when the 'ldd' is done, there is a 'linux-gate.so.1' that 
# points to nothing (or a 90xb.....), and it also does not pick up
# some files that start with a '/'. To fix this, I am doing the ldd
# to a file called ldlist, then going back into the file and pulling
# out the libs that start with '/'
# 
# Randy K.
#
# The original code worked fine on 2.4 kernel systems. Kernel 2.6
# introduced an internal library called 'linux-gate.so.1'. This 
# 'phantom' library caused non-critical errors to display during the 
# copy since the file does not actually exist on the file system. 
# To fix re-direct output of ldd to a file, parse the file and get 
# library files that start with /
#

# create temporary files with mktemp, if that doesn't work for some reason use
# the old method with $HOME/ldlist[2] (so I don't have to check the existence
# of the mktemp package / binary at the beginning
#
# Maksim K
#
# Don't know why, but redirection operator "&>/dev/null" is not working on Debian 9
# (where /bin/sh -> /bin/dash), so, I've replaced it to the ">/dev/null 2>&1".
TMPFILE1=`mktemp -q` >/dev/null 2>&1 || TMPFILE1="${HOME}/ldlist"; if [ -x ${TMPFILE1} ]; then mv -v ${TMPFILE1} ${TMPFILE1}.bak;fi 
TMPFILE2=`mktemp -q` >/dev/null 2>&1 || TMPFILE2="${HOME}/ldlist2"; if [ -x ${TMPFILE2} ]; then mv -v ${TMPFILE2} ${TMPFILE2}.bak;fi 

for app in $APPS;  do
    # First of all, check that this application exists
    if [ -x $app ]; then
        # Check that the directory exists; create it if not.
#        app_path=`echo $app | sed -e 's#\(.\+\)/[^/]\+#\1#'`
        app_path=`dirname $app`
        if ! [ -d .$app_path ]; then
            mkdir -p .$app_path
        fi

		# If the files in the chroot are on the same file system as the
		# original files you should be able to use hard links instead of
		# copying the files, too. Symbolic links cannot be used, because the
		# original files are outside the chroot.
		copy_or_link -p $app .$app

        # get list of necessary libraries
        ldd $app >> ${TMPFILE1}
    fi
done

# Clear out any old temporary file before we start
for libs in `cat ${TMPFILE1}`; do
   frst_char="`echo $libs | cut -c1`"
   if [ "\"$frst_char\"" = "\"/\"" ]; then
#   if [ "$frst_char" = "/" ]; then
     echo "$libs" >> ${TMPFILE2}
   fi
done

for lib in `cat ${TMPFILE2}`; do
    mkdir -p .`dirname $lib` > /dev/null 2>&1

	# If the files in the chroot are on the same file system as the original
	# files you should be able to use hard links instead of copying the files,
	# too. Symbolic links cannot be used, because the original files are
	# outside the chroot.
    copy_or_link $lib .$lib
done

#
# Now, cleanup the 2 files we created for the library list
#
#/bin/rm -f ${HOME}/ldlist
#/bin/rm -f ${HOME}/ldlist2
/bin/rm -f ${TMPFILE1}
/bin/rm -f ${TMPFILE2}

# Necessary files that are not listed by ldd.
#
# There might be errors because of files that do not exist but in the end it
# may work nevertheless (I added new file names at the end without deleting old
# ones for reasons of backward compatibility).
# So please test ssh/scp before reporting a bug.
if [ "$DISTRO" = SUSE ]; then
  copy_or_link /lib/libnss_compat.so.2 /lib/libnss_files.so.2 /lib/libnss_dns.so.2 /lib/libxcrypt.so.1 ${JAILPATH}/lib/
elif [ "$DISTRO" = FEDORA ]; then
  copy_or_link /lib/libnss_compat.so.2 /lib/libnsl.so.1 /lib/libnss_files.so.2 /lib/ld-linux.so.2 /lib/ld-ldb.so.3 /lib/ld-lsb.so.3 /lib/libnss_dns.so.2 /lib/libxcrypt.so.1 ${JAILPATH}/lib/
  copy_or_link /lib/*.* ${JAILPATH}/lib/
  copy_or_link /usr/lib/libcrack.so.2 ${JAILPATH}/usr/lib/
elif [ "$DISTRO" = REDHAT ]; then
  copy_or_link /lib/libnss_compat.so.2 /lib/libnsl.so.1 /lib/libnss_files.so.2 /lib/ld-linux.so.2 /lib/ld-lsb.so.1 /lib/libnss_dns.so.2 /lib/libxcrypt.so.1 ${JAILPATH}/lib/
  # needed for scp on RHEL
  echo "export LD_LIBRARY_PATH=/usr/kerberos/lib" >> ${JAILPATH}/etc/profile
elif [ "$DISTRO" = DEBIAN ]; then
  if [ -d /lib/x86_64-linux-gnu/ ]; then
    copy_or_link /lib/x86_64-linux-gnu/libnss_compat.so.2 /lib/x86_64-linux-gnu/libnsl.so.1 /lib/x86_64-linux-gnu/libnss_files.so.2 /lib/x86_64-linux-gnu/libcap.so.2 /lib/x86_64-linux-gnu/libnss_dns.so.2 ${JAILPATH}/lib/
  else
    copy_or_link /lib/libnss_compat.so.2 /lib/libnsl.so.1 /lib/libnss_files.so.2 /lib/libcap.so.1 /lib/libnss_dns.so.2 ${JAILPATH}/lib/
  fi
else
  copy_or_link /lib/libnss_compat.so.2 /lib/libnsl.so.1 /lib/libnss_files.so.2 /lib/libcap.so.1 /lib/libnss_dns.so.2 ${JAILPATH}/lib/
fi

if [ $PAM = "copy" ]; then
  # if you are using PAM you need stuff from /etc/pam.d/ in the jail,
  echo "Copying files from /etc/pam.d/ to jail"
  copy_or_link /etc/pam.d/* ${JAILPATH}/etc/pam.d/

  # ...and of course the PAM-modules...
  echo "Copying PAM-Modules to jail"
  if [ -d /lib/security ]; then
      copy_or_link /lib/security/* ${JAILPATH}/lib/
  fi
  if [ -d /lib/x86_64-linux-gnu/security ]; then
    copy_or_link -r /lib/x86_64-linux-gnu/security ${JAILPATH}/lib/
  fi

  # ...and something else useful for PAM
  copy_or_link -r /etc/security ${JAILPATH}/etc/
  copy_or_link /etc/login.defs ${JAILPATH}/etc/

  if [ -f /etc/DIR_COLORS ] ; then
    copy_or_link /etc/DIR_COLORS ${JAILPATH}/etc/
  fi 
fi # endif for checking $PAM

# Don't give more permissions than necessary
if [ $LINK != "ln" ]; then
  chown root.root ${JAILPATH}/bin/su
  chmod 700 ${JAILPATH}/bin/su
fi


exit
