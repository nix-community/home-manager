{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.uget = {
      enable = true;
      integrator = {
        enable = true;
        browsers =
          [ "brave" "chrome" "chromium" "firefox" "librewolf" "vivaldi" ];
      };
    };

    nmt.script = if pkgs.stdenv.hostPlatform.isDarwin then ''
      for dir in "BraveSoftware/Brave-Browser" "Google/Chrome" "Chromium" "Mozilla" "LibreWolf" "Vivaldi"; do
        assertFileExists "home-files/Library/Application Support/$dir/NativeMessagingHosts/com.ugetdm.firefox.json"
      done

      for dir in "Google/Chrome" "Chromium" "Vivaldi"; do
        assertFileExists "home-files/Library/Application Support/$dir/policies/managed/com.ugetdm.firefox.json"
      done
    '' else ''
      for dir in "BraveSoftware/Brave-Browser" "google-chrome" "chromium" "vivaldi"; do
        assertFileExists "home-files/.config/$dir/NativeMessagingHosts/com.ugetdm.firefox.json"
      done

      for dir in "google-chrome" "chromium" "vivaldi"; do
        assertFileExists "home-files/.config/$dir/policies/managed/com.ugetdm.firefox.json"
      done

      for dir in ".mozilla" ".librewolf"; do
        assertFileExists "home-files/$dir/native-messaging-hosts/com.ugetdm.firefox.json"
      done
    '';
  };
}
