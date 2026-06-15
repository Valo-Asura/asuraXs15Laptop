# Android device and recovery tooling for the Galaxy S24 workflow.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    android-tools # adb, fastboot, logcat
    heimdall # Samsung download-mode flashing/recovery utility
    jmtpfs # FUSE MTP mount helper
    mtpfs # alternate MTP mount helper
    scrcpy # Android screen/control bridge over adb
  ];
}
