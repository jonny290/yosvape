YOSVape
=======
YOSVape, long story short, is a really fancy herbal vaporizer.
This is its code base.

Basic idea is that vapelog.pl keeps a serial connection open to the
Arduino which is loaded with yosvape.ino. Every second, yosvape.ino sends a 
status line, and constantly listens for mode changes.

vapelog.pl handles the I/O for the serial and disk. (/vape is a ramdisk)
vapelog.sh keeps vapelog.pl running.

yosvape.pl is the Irssi script interface. It interacts with the system through 
the /vape filesystem.

yosvape.pm also uses the /vape filesystem to interact and control; this is a 
Dancer module to provide a basic webui. It has not been worked on much at all 
so far, and needs help.

If you have any suggestions or tips, please let me know.

-290