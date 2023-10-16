{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.uget;
  browsers = [ "brave" "chrome" "chromium" "firefox" "librewolf" "vivaldi" ];

in {
  meta.maintainers = [ maintainers.poelzi ];

  options.programs.uget = {
    enable = mkEnableOption "uget download manager";

    package = mkOption {
      type = types.package;
      default = pkgs.uget;
      defaultText = literalExpression "pkgs.uget";
      description = "uget package to install.";
    };

    integrator = {
      package = mkOption {
        type = types.package;
        default = pkgs.uget-integrator;
        defaultText = literalExpression "pkgs.uget-integrator";
        description = "uget-integrator package to install.";
      };

      enable = mkEnableOption "the uget-integrator extension host application";

      browsers = mkOption {
        type = types.listOf (types.enum browsers);
        default = browsers;
        example = [ "firefox" ];
        description = "Which browsers to install browserpass for";
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ]
      ++ (lib.lists.optional cfg.integrator.enable cfg.integrator.package);

    # home.file = browser-extension.nativeHostFiles cfg.integrator.browsers (
    #     fold (x: y: x // {"${y}" = "${cfg.integrator.package}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";}));
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
          "${dir}/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
        }]
      else if x == "chrome" then
        let
          dir = if isDarwin then
            "Library/Application Support/Google/Chrome/NativeMessagingHosts"
          else
            ".config/google-chrome/NativeMessagingHosts";
        in [{
          "${dir}/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
          "${dir}/../policies/managed/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
        }]
      else if x == "chromium" then
        let
          dir = if isDarwin then
            "Library/Application Support/Chromium/NativeMessagingHosts"
          else
            ".config/chromium/NativeMessagingHosts";
        in [
          {
            "${dir}/com.ugetdm.firefox.json".source =
              "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
          }
          {
            "${dir}/../policies/managed/com.ugetdm.firefox.json".source =
              "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
          }
        ]
      else if x == "firefox" then
        let
          dir = if isDarwin then
            "Library/Application Support/Mozilla/NativeMessagingHosts"
          else
            ".mozilla/native-messaging-hosts";
        in [{
          "${dir}/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
        }]
      else if x == "librewolf" then
        let
          dir = if isDarwin then
            "Library/Application Support/LibreWolf/NativeMessagingHosts"
          else
            ".librewolf/native-messaging-hosts";
        in [{
          "${dir}/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
        }]

      else if x == "vivaldi" then
        let
          dir = if isDarwin then
            "Library/Application Support/Vivaldi/NativeMessagingHosts"
          else
            ".config/vivaldi/NativeMessagingHosts";
        in [{
          "${dir}/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
          "${dir}/../policies/managed/com.ugetdm.firefox.json".source =
            "${pkgs.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
        }]
      else
        throw "unknown browser ${x}") cfg.integrator.browsers);
  };
}
