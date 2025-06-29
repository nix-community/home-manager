{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.browserpass;
  browsers = [
    "brave"
    "chrome"
    "chromium"
    "firefox"
    "librewolf"
    "vivaldi"
  ];
in
{
  options = {
    programs.browserpass = {
      enable = lib.mkEnableOption "the browserpass extension host application";

      browsers = lib.mkOption {
        type = lib.types.listOf (lib.types.enum browsers);
        default = browsers;
        example = [ "firefox" ];
        description = "Which browsers to install browserpass for";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.foldl' (a: b: a // b) { } (
      lib.concatMap (
        x:
        with pkgs.stdenv;
        if x == "brave" then
          let
            dir =
              if isDarwin then
                "Library/Application Support/BraveSoftware/Brave-Browser"
              else
                ".config/BraveSoftware/Brave-Browser";
          in
          [
            {
              # Policies are read from `/etc/brave/policies` only
              # https://github.com/brave/brave-browser/issues/19052
              "${dir}/NativeMessagingHosts/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
            }
          ]
        else if x == "chrome" then
          let
            dir = if isDarwin then "Library/Application Support/Google/Chrome" else ".config/google-chrome";
          in
          [
            {
              "${dir}/NativeMessagingHosts/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
              "${dir}/policies/managed/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
            }
          ]
        else if x == "chromium" then
          let
            dir = if isDarwin then "Library/Application Support/Chromium" else ".config/chromium";
          in
          [
            {
              "${dir}/NativeMessagingHosts/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
            }
            {
              "${dir}/policies/managed/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
            }
          ]
        else if x == "firefox" then
          let
            dir =
              if isDarwin then
                "Library/Application Support/Mozilla/NativeMessagingHosts"
              else
                ".mozilla/native-messaging-hosts";
          in
          [
            {
              "${dir}/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/firefox/com.github.browserpass.native.json";
            }
          ]
        else if x == "librewolf" then
          let
            dir =
              if isDarwin then
                "Library/Application Support/LibreWolf/NativeMessagingHosts"
              else
                ".librewolf/native-messaging-hosts";
          in
          [
            {
              "${dir}/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/firefox/com.github.browserpass.native.json";
            }
          ]

        else if x == "vivaldi" then
          let
            dir = if isDarwin then "Library/Application Support/Vivaldi" else ".config/vivaldi";
          in
          [
            {
              "${dir}/NativeMessagingHosts/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/hosts/chromium/com.github.browserpass.native.json";
              "${dir}/policies/managed/com.github.browserpass.native.json".source =
                "${pkgs.browserpass}/lib/browserpass/policies/chromium/com.github.browserpass.native.json";
            }
          ]
        else
          throw "unknown browser ${x}"
      ) cfg.browsers
    );
  };
}
