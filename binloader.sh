#!/bin/sh
# Android Bin Loader
# This program is able to load custom binaries or script files to the system using symlink.

# Installation Steps:
# 1. Make sure Magisk is installed;
# 2. Make sure /bin is magic mounted;
# 3. Put this binloader.sh into /data/adb/service.d;
# 4. Reboot and it will be available in terminal.

# Created by hdtune2k

# Const values:
# Init log file location:
templog_path=/sdcard/blinit.log
# Bin loader work path:
defpath=/data/binloader

# Change work dir:
cd $defpath/tmp

# Version Info:
blcore_ver="1.1"

# First deployment:
function first_deploy() {
 
 # Creates work directories:
 mkdir $defpath
 mkdir $defpath/mods
 mkdir $defpath/configs
 mkdir $defpath/tmp
 mkdir $defpath/configs/linkers
 
 # Creates configs:
 echo $defpath > $defpath/configs/defpath
 # Set installed mark:
 echo 1 > $defpath/configs/inststate
 
}

function re_deploy() {
 
 # Force redeploy to reset all settings:
 # Remove old files:
 rm -rf $defpath
 # Redeploy:
 first_deploy

}

function strecho() {

 case $1 in
 vdone)
  echo "Package verified."
 ;;
 indone)
  echo "Package installed successfully."
 ;;
 help)
  echo "BINLOADER - A program that is able to load custom binaries to system."
  echo "Usage: binloader (blcore) [Options]"
  echo "Options:"
  echo "   install [path] - install a new package."
  echo "   remove [path] - remove a installed package."
  echo "   ls - list all installed packages."
  echo "   ver - show blcore version information."
  echo "   status - show blcore status."
  echo "   help - show this help documents."
  echo "Created by hdtune2k."
 ;;
 rmdone)
  echo "Package removed."
 ;;
 unpaked)
  echo "Package unpacked successfully."
  echo "Verifying package information..."
 ;;
 nopkginfo)
  echo "Error: pkginfo file not found."
 ;;
 noprogfiles)
  echo "Error: no program files found."
 ;;
 noexec)
  echo "Error: no executables found."
 ;;
 fnf)
  echo "Error: file not found."
 ;;
 pvf)
  echo "Error: package verification failure."
 ;;
 upakfail)
  echo "Error: installation failure."
  echo "Unsupported package or broken package specified."
 ;;
 pinfo)
  echo Loaded package information:
  echo Name: $2
  echo Version: $3
  echo Executable: $4
  echo Exec name: $5
  if [ -n "$6" ]; then
   echo Run at Boot: $6
  fi
  # install confirmation:
  echo -n "Proceed installation?(y/n):"
  read result
  case $result in
  y)
   echo "Installing package $2 ..."
  ;;
  n)
   echo "Aborted."
   exit
  ;;
  *)
   echo "Error: invalid option."
   exit
  ;;
  esac
 ;;
 inst_showinfo)
  echo "Start to unpack package..."
 ;;
 pnf)
  echo "Error: no such package found at installed list."
 ;;
 updconfirm)
  
  # Get info of installed pkg:
  installed_ver=`cat $defpath/mods/$2/pkginfo|grep version|cut -d '[' -f2|cut -d ']' -f1`
  echo "Detected an old installation of this package."
  echo "Installed version: $installed_ver"
  echo "Replace version: $3"
  echo -n "Update installed package?(y/n):"
  read rpres
  case $rpres in
  y)
   echo "The old package has been removed."
  ;;
  n)
   echo "Aborted."
   exit
  ;;
  *)
   echo "Error: invalid option."
   exit
  ;;
  esac
 ;;
 rabnf)
  echo "Error: run at boot executable not found."
 ;;
 onlyrabins)
  echo "<!> This package cannot access by terminal interface, it only runs at device boot."
  echo "Loaded package information:"
  echo "Name: $2"
  echo "Run at Boot Exec: $3"
  echo -n "Proceed installation?(y/n):"
  read rpres
  case $rpres in
  y)
   echo "Installing package ..."
  ;;
  n)
   echo "Aborted."
   exit
  ;;
  *)
   echo "Error: invalid option."
   exit
  ;;
  esac
 ;;
 rabdetect)
  echo "Boot script generated."
 ;;
 execnameerr)
  echo "Error: package exec name not specified."
 ;;
 noinput)
  echo "Error: invalid option specified."
  echo "Type 'blcore help' to show help documents."
 ;;
 esac

 # Exit detect:
 case $2 in
  exit)
   exit 0
  ;;
 esac

}

function boot_init() {

 # Mounts filesystems:
 mount -t tmpfs tmpfs $defpath/tmp

 # Self injection:
 ln -s /data/adb/service.d/binloader.sh /bin/binloader
 ln -s /data/adb/service.d/binloader.sh /bin/blcore

 # Mods boot injection:
 for file in ls $defpath/configs/linkers/*.linker
 do
  $file
 done
 
 # Mark mods injection state:
 echo 1 > $defpath/tmp/mod_injection

 exit 0
 
}

function version() {
 
 echo "Current binloader core version: $blcore_ver ."

}

# Install mod package to system
function pkg_install() {

 # Displays info:
 strecho inst_showinfo

 # Create installation work dir:
 if [ ! -d $defpath/tmp/inst ]; then
  mkdir $defpath/tmp/inst
 elif [ -d $defpath/tmp/inst ]; then
  rm -rf $defpath/tmp/inst
  mkdir $defpath/tmp/inst
 fi

 # Check if available:
 if [ ! -f $1 ]; then
  strecho fnf exit
 fi

 # Unpack package:
 cd $defpath/tmp/inst # Change work dir to inst dir
 cp $1 $defpath/tmp/inst/preinst.tar
 tar -xvf $defpath/tmp/inst/preinst.tar > /dev/null

 cd $defpath/tmp # Change it back
 
 # Verify package:
 # Check contents:
 if [ ! -f $defpath/tmp/inst/pkginfo ]; then
  strecho nopkginfo
  strecho upakfail exit
 fi
 if [ ! -d $defpath/tmp/inst/programs ]; then
  strecho noprogfiles
  strecho upakfail exit
 fi
 

  strecho unpaked
 
 # Load pkginfo config:
 pkgname=`cat $defpath/tmp/inst/pkginfo|grep pkgname|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadname
 pkgversion=`cat $defpath/tmp/inst/pkginfo|grep version|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadver
 execpath=`cat $defpath/tmp/inst/pkginfo|grep execpath|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadepath
 execname=`cat $defpath/tmp/inst/pkginfo|grep execname|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadename
 runatboot=`cat $defpath/tmp/inst/pkginfo|grep runatboot|cut -d '[' -f2|cut -d ']' -f1`

 # Default only run at boot as false
 onlyrab=0

 # Verify pkginfo:
 if [ ! -n "$pkgname" ]; then
    strecho pvf exit
 fi
 if [ ! -n "$pkgversion" ]; then
    strecho pvf exit
 fi
 if [ ! -n "$execpath" ]; then
   if [ ! -n "$runatboot" ]; then
    strecho pvf exit
   fi
 fi
 # Execname and onlyrunatboot state check:
 if [ ! -n "$execname" ]; then
   # Exit when runatboot not exist
   if [ ! -n "$runatboot" ]; then
    strecho pvf exit
   fi
   # Exit when execpath without execname
   if [ -n "$execpath" ]; then
      strecho execnameerr exit
   fi
   onlyrab=1 # Only-run-at-boot package identify.
 fi

 # Executable path verify:
 if [ ! -f $defpath/tmp/inst/programs/$execpath -a $onlyrab -eq 0 ]; then
  strecho noexec
  strecho upakfail exit
 fi

 # Onlyrab package installation:
 if [ $onlyrab -eq 1 ]; then
   if [ ! -f $defpath/tmp/inst/programs/$runatboot ]; then
    strecho rabnf exit
   fi
   # Confirmation:
   strecho onlyrabins $pkgname $runatboot
    # Check if already installed:
    if [ -d $defpath/mods/$pkgname ]; then
     strecho updconfirm $pkgname $pkgversion
     # Removes old copies:
     rm -rf $defpath/mods/$pkgname
     if [ -f $defpath/configs/linkers/$pkgname.linker ]; then
      rm $defpath/configs/linkers/$pkgname.linker
     fi
    fi
   # Copy new files:
   mkdir $defpath/mods/$pkgname
   cp $defpath/tmp/inst/pkginfo $defpath/mods/$pkgname > /dev/null
   cp -r $defpath/tmp/inst/programs/* $defpath/mods/$pkgname > /dev/null
   chmod 0755 $defpath/mods/$pkgname/*
   # Create runner:
   echo "#!/bin/sh" >> /data/adb/service.d/$pkgname.sh
   echo "$defpath/mods/$pkgname/$runatboot" >> /data/adb/service.d/$pkgname.sh
   chmod 0755 /data/adb/service.d/$pkgname.sh
   strecho indone exit
   # End of RaB installation
 fi
 # Note: if onlyrab package installed, program will exit till here.

 # Normal package and normal runatboot package installation:
 strecho vdone
 # Confirmation:
 strecho pinfo $pkgname $pkgversion $execpath $execname $runatboot

 # Check if already installed:
 if [ -d $defpath/mods/$pkgname ]; then
  strecho updconfirm $pkgname $pkgversion
  # Removes old copies:
  rm -rf $defpath/mods/$pkgname
  if [ -f $defpath/configs/linkers/$pkgname.linker ]; then
   rm $defpath/configs/linkers/$pkgname.linker
  fi
 fi

 # Verify normal run at boot:
 if [ -n "$runatboot" ]; then
  strecho rabdetect
  echo "#!/bin/sh" >> /data/adb/service.d/$pkgname.sh
  echo "$defpath/mods/$pkgname/$runatboot" >> /data/adb/service.d/$pkgname.sh
  chmod 0755 /data/adb/service.d/$pkgname.sh
 fi

 # Install package into system:

 # Create mod dir:
 mkdir $defpath/mods/$pkgname
 # Copy new files:
 cp $defpath/tmp/inst/pkginfo $defpath/mods/$pkgname > /dev/null
 cp -r $defpath/tmp/inst/programs/* $defpath/mods/$pkgname > /dev/null
 # Create linker:
 echo "#!/bin/sh" >> $defpath/configs/linkers/$pkgname.linker
 echo "ln -s $defpath/mods/$pkgname/$execpath /bin/$execname" >> $defpath/configs/linkers/$pkgname.linker
 # Change perm:
 chmod 0755 $defpath/mods/$pkgname/*
 chmod 0755 $defpath/configs/linkers/$pkgname.linker

 strecho indone
 # End of norm installation, program exits.

}

function pkg_remove() {
 
 # Check if package installed:
 if [ ! -d $defpath/mods/$1 ]; then
  strecho pnf exit
 fi

 # Check if runatboot enabled:
 if [ -f /data/adb/service.d/$1.sh ]; then
   rm /data/adb/service.d/$1.sh
 fi

 # Remove specified package:
 rm -rf $defpath/mods/$1
 if [ -f $defpath/configs/linkers/$1.linker ];then
  rm $defpath/configs/linkers/$1.linker > /dev/null
 fi

 strecho rmdone

}

function pkg_ls() {
 
 # List installed packages:
 ls $defpath/mods

}

function blstatus() {
 
 # Loader status display:
 loaderstats=`cat $defpath/configs/inststate`
 modinjectstats=`cat $defpath/tmp/mod_injection`
 
 case $loaderstats in
 1)
  echo Loader installation: True
 ;;
 0)
  echo Loader installation: Reset
  reset_stat=2
 ;;
 *)
  echo Loader installation: Invalid
  inv_stat=1
 ;;
 esac
 
 case $modinjectstats in
 1)
  echo Mod injection: True
 ;;
 0)
  echo Mod injection: False
 ;;
 *)
  echo Mod injection: Invalid
  inv_stat=1
 ;;
 esac
 
 if [ $inv_stat -eq 1 ]; then
  echo "<Warn> invalid control file modification."
 fi
 if [ $reset_stat -eq 2 ]; then
  echo "<Warn> loader will reset at next boot."
 fi
 
 exit
 
}

# Main Program Area
# Following codes will be executed at every boot:

if [ ! -f $defpath/tmp/mod_injection ]; then

 # Check binloader deployment state:
 if [ ! -f $defpath/configs/inststate ]; then
  first_deploy
 fi
 # Force redeployment when state read as 0:
 if [ `cat $defpath/configs/inststate` == 0 ]; then
  re_deploy
 fi

 # Boot Proccess:
 boot_init

fi

# End of boot code.

# CLI responder:
case $1 in
help)
 strecho help
;;
install)
 pkg_install $2
;;
remove)
 pkg_remove $2
;;
ls)
 pkg_ls
;;
ver)
 version
;;
status)
 blstatus
;;
*)
 strecho noinput exit
;;
esac

exit 0
