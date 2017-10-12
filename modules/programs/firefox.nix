{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.firefox;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.firefox = {
      enable = mkEnableOption "Firefox";

      package = mkOption {
        type = types.package;
        default = pkgs.firefox-unwrapped;
        defaultText = "pkgs.firefox-unwrapped";
        description = "The unwrapped Firefox package to use.";
      };

      enableAdobeFlash = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the unfree Adobe Flash plugin.";
      };

      enableGoogleTalk = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the unfree Google Talk plugin.";
      };
      enableIcedtea = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the java applet plugin.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      let
        # A bit of hackery to force a config into the wrapper.
        browserName = cfg.package.browserName
          or (builtins.parseDrvName cfg.package.name).name;

        fcfg = setAttrByPath [browserName] {
          enableAdobeFlash = cfg.enableAdobeFlash;
          enableGoogleTalkPlugin = cfg.enableGoogleTalk;
          icedtea = cfg.enableIcedtea;
        };

        wrapper = pkgs.wrapFirefox.override {
          config = fcfg;
        };
      in
        [ (wrapper cfg.package { }) ];
  };
}
