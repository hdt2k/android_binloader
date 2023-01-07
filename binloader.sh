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
blcore_ver="1.0.1"

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
  echo "Package verification succeed."
 ;;
 indone)
  echo "Package installation succeed."
 ;;
 help)
  echo "BINLOADER - A program that is able to load custom binaries to system."
  echo "Usage: binloader (blcore) [Options]"
  echo "Options:"
  echo "   install [pkg_path] - Install a new mod package."
  echo "   remove [pkg_path] - Remove a installed package."
  echo "   ls - list all installed packages."
  echo "   ver - show blcore version information."
  echo "   help - Show this help documents."
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
  echo "Error: PkgInfo file not found."
 ;;
 noprogfiles)
  echo "Error: no program files found."
 ;;
 noexec)
  echo "Error: No executables found."
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
  echo "Binloader Core Version $blcore_ver"
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
 echo Mod_Injection_Executed_Completed > $defpath/tmp/injection_status

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
 
 # Verify and load PkgInfo config:
 pkgname=`cat $defpath/tmp/inst/pkginfo|grep pkgname|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadname
 pkgversion=`cat $defpath/tmp/inst/pkginfo|grep version|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadver
 execpath=`cat $defpath/tmp/inst/pkginfo|grep execpath|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadepath
 execname=`cat $defpath/tmp/inst/pkginfo|grep execname|cut -d '[' -f2|cut -d ']' -f1`
  strecho loadename

 if [ ! -n "$pkgname" ]; then
    strecho pvf exit
 fi
 if [ ! -n "$pkgversion" ]; then
    strecho pvf exit
 fi
  if [ ! -n "$execpath" ]; then
    strecho pvf exit
 fi
 if [ ! -n "$execname" ]; then
    strecho pvf exit
 fi
 if [ ! -f $defpath/tmp/inst/programs/$execpath ]; then
  strecho noexec
  strecho upakfail exit
 fi

 strecho vdone
 strecho pinfo $pkgname $pkgversion $execpath $execname

 # Check if already installed:
 if [ -d $defpath/mods/$pkgname ]; then

  strecho updconfirm $pkgname $pkgversion
  # Removes old copies:
  rm -rf $defpath/mods/$pkgname
  rm $defpath/configs/linkers/$pkgname.linker

 fi

 # Install package into system:

 # Create mod dir:
 mkdir $defpath/mods/$pkgname
 # Copy new files:
 cp $defpath/tmp/inst/pkginfo $defpath/mods/$pkgname
 cp -r $defpath/tmp/inst/programs/* $defpath/mods/$pkgname
 # Create linker:
 echo "#!/bin/sh" >> $defpath/configs/linkers/$pkgname.linker
 echo "ln -s $defpath/mods/$pkgname/$execpath /bin/$execname" >> $defpath/configs/linkers/$pkgname.linker
 # Change perm:
 chmod 0755 $defpath/mods/$pkgname/*
 chmod 0755 $defpath/configs/linkers/$pkgname.linker

 strecho indone

}

function pkg_remove() {
 
 # Check if package installed:
 if [ ! -d $defpath/mods/$1 ]; then
  strecho pnf exit
 fi

 # Remove specified package:
 rm -rf $defpath/mods/$1
 rm $defpath/configs/linkers/$1.linker

 strecho rmdone

}

function pkg_ls() {
 
 # List installed packages:
 ls $defpath/mods

}

# Main Program Area
# Following codes will be executed at every boot:

if [ ! -f $defpath/tmp/injection_status ]; then

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
esac

exit 0
