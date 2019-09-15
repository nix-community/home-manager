{ config, lib, pkgs, ... }:

with lib;

let
  browsers = [
    "chrome"
    "chromium"
    "firefox"
    "vivaldi"
  ];
in {
  options = {
    programs.browserpass = {
      enable = mkEnableOption "the browserpass extension host application";

      browsers = mkOption {
        type = types.listOf (types.enum browsers);
        default = browsers;
        example = [ "firefox" ];
        description = "Which browsers to install browserpass for";
      };
    };
  };

  config = mkIf config.programs.browserpass.enable {
    home.file = builtins.concatLists (with pkgs.stdenv; map (x:
      if x == "chrome" then
        let dir = if isDarwin
          then "Library/Application Support/Google/Chrome/NativeMessagingHosts"
          else ".config/google-chrome/NativeMessagingHosts";
        in [
          {
            target = "${dir}/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          }
          {
            target = "${dir}/../policies/managed/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
          }
        ]
      else if x == "chromium" then
        let dir = if isDarwin
          then "Library/Application Support/Chromium/NativeMessagingHosts"
          else ".config/chromium/NativeMessagingHosts";
        in [
          {
            target = "${dir}/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          }
          {
            target = "${dir}/../policies/managed/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
          }
        ]
      else if x == "firefox" then
        [ {
          target = (if isDarwin
            then "Library/Application Support/Mozilla/NativeMessagingHosts"
            else ".mozilla/native-messaging-hosts")
            + "/com.github.browserpass.native.json";
          source = "${pkgs.browserpass}/lib/browserpass/hosts/firefox/com.github.browserpass.native.json";
        } ]
      else if x == "vivaldi" then
        let dir = if isDarwin
          then "Library/Application Support/Vivaldi/NativeMessagingHosts"
          else ".config/vivaldi/NativeMessagingHosts";
        in [
          {
            target = "${dir}/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          }
          {
            target = "${dir}/../policies/managed/com.github.browserpass.native.json";
            source = "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
          }
        ]
      else throw "unknown browser ${x}") config.programs.browserpass.browsers);
  };
}
