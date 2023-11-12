{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.browserpass = {
      enable = true;
      browsers =
        [ "brave" "chrome" "chromium" "firefox" "librewolf" "vivaldi" ];
    };

    nmt.script = if pkgs.stdenv.hostPlatform.isDarwin then ''
      for dir in "BraveSoftware/Brave-Browser" "Google/Chrome" "Chromium" "Mozilla" "LibreWolf" "Vivaldi"; do
        assertFileExists "home-files/Library/Application Support/$dir/NativeMessagingHosts/com.github.browserpass.native.json"
      done

      for dir in "Google/Chrome" "Chromium" "Vivaldi"; do
        assertFileExists "home-files/Library/Application Support/$dir/policies/managed/com.github.browserpass.native.json"
      done
    '' else ''
      for dir in "BraveSoftware/Brave-Browser" "google-chrome" "chromium" "vivaldi"; do
        assertFileExists "home-files/.config/$dir/NativeMessagingHosts/com.github.browserpass.native.json"
      done

      for dir in "google-chrome" "chromium" "vivaldi"; do
        assertFileExists "home-files/.config/$dir/policies/managed/com.github.browserpass.native.json"
      done

      for dir in ".mozilla" ".librewolf"; do
        assertFileExists "home-files/$dir/native-messaging-hosts/com.github.browserpass.native.json"
      done
    '';
  };
}
