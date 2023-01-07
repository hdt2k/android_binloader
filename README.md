# Android Binaries Loader
A simple program that could load various executables into Android system.

## About this script
This program is a shell script working on android, in order to loads various executable files 
into system, avoids us making a complex Magisk module when we just needs a single executable 
file installed into the system. In order to keep this script simple, it only needs a single sh
file to install and use.

## Tested System Environment
This program has been tested working fine at vivo V2056A with android 11 installed.
Warning: This program comes with no WARRANTY, use it with your own risks, the author DOES NOT
responsible for any data loses or device damage of yours.

## Installation Guide
1. Make sure the device was unlocked and installed the lastest Magisk;
2. An android terminal emulator app installed (Termux is recommended);
3. Install any module that is able to magic mount the '/system/bin' directory.
You can make your own Magisk module to make "/system/bin" magic mounted, or just 
install a same function module (nano for Android NDK module is tested working, 
you can get it at Magisk's official repo);
3. Copy the 'binloader.sh' to '/data/adb/service.d' directory using root file 
manager, and give it 0755 permission by using command 'chmod 0755 /data/adb/service.d/binloader.sh';
4. Reboot the system and it will automatically installed into your system.

## Usage
Hint: This is a terminal app, please use terminal interface to interact with it.
### How to install a package
This script can manage a simple package that contains your own executables.
To install a new package, just type 'blcore install [full package path]' in terminal or adb,
follow the step that script displays to finish whole installation. If the package was already
installed, the loader will ask for replacement.
## How to remove a package
To remove a package, just type 'blcore remove [package name]'. If you forgotten the name, you
can use 'blcore ls' to list all installed packages.

