{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.browserpass;
  browsers = [ "brave" "chrome" "chromium" "firefox" "librewolf" "vivaldi" ];
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

  config = mkIf cfg.enable {
    home.file = foldl' (a: b: a // b) { } (concatMap (x:
      with pkgs.stdenv;
      if x == "brave" then
        let
          dir = if isDarwin then
            "Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
          else
            ".config/BraveSoftware/Brave-Browser/NativeMessagingHosts";
        in [{
          # Policies are read from `/etc/brave/policies` only
          # https://github.com/brave/brave-browser/issues/19052
          "${dir}/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
        }]
      else if x == "chrome" then
        let
          dir = if isDarwin then
            "Library/Application Support/Google/Chrome/NativeMessagingHosts"
          else
            ".config/google-chrome/NativeMessagingHosts";
        in [{
          "${dir}/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          "${dir}/../policies/managed/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
        }]
      else if x == "chromium" then
        let
          dir = if isDarwin then
            "Library/Application Support/Chromium/NativeMessagingHosts"
          else
            ".config/chromium/NativeMessagingHosts";
        in [
          {
            "${dir}/com.github.browserpass.native.json".source =
              "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          }
          {
            "${dir}/../policies/managed/com.github.browserpass.native.json".source =
              "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
          }
        ]
      else if x == "firefox" then
        let
          dir = if isDarwin then
            "Library/Application Support/Mozilla/NativeMessagingHosts"
          else
            ".mozilla/native-messaging-hosts";
        in [{
          "${dir}/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/hosts/firefox/com.github.browserpass.native.json";
        }]
      else if x == "librewolf" then
        let
          dir = if isDarwin then
            "Library/Application Support/LibreWolf/NativeMessagingHosts"
          else
            ".librewolf/native-messaging-hosts";
        in [{
          "${dir}/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/hosts/firefox/com.github.browserpass.native.json";
        }]

      else if x == "vivaldi" then
        let
          dir = if isDarwin then
            "Library/Application Support/Vivaldi/NativeMessagingHosts"
          else
            ".config/vivaldi/NativeMessagingHosts";
        in [{
          "${dir}/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
          "${dir}/../policies/managed/com.github.browserpass.native.json".source =
            "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
        }]
      else
        throw "unknown browser ${x}") cfg.browsers);
  };
}
