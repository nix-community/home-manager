{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.firefox;

  extensionPath = "extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

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

      extensions = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExample ''
          with pkgs.nur.repos.rycee.firefox-addons; [
            https-everywhere
            privacy-badger
          ]
        '';
        description = ''
          List of Firefox add-on packages to install. Note, it is
          necessary to manually enable these extensions inside Firefox
          after the first installation.
        '';
      };

      enableAdobeFlash = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the unfree Adobe Flash plugin.";
      };

      enableGoogleTalk = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the unfree Google Talk plugin. This option
          is <emphasis>deprecated</emphasis> and will only work if

          <programlisting language="nix">
          programs.firefox.package = pkgs.firefox-esr-52-unwrapped;
          </programlisting>

          and the <option>plugin.load_flash_only</option> Firefox
          option has been disabled.
        '';
      };

      enableIcedTea = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Java applet plugin. This option is
          <emphasis>deprecated</emphasis> and will only work if

          <programlisting language="nix">
          programs.firefox.package = pkgs.firefox-esr-52-unwrapped;
          </programlisting>

          and the <option>plugin.load_flash_only</option> Firefox
          option has been disabled.
        '';
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
          icedtea = cfg.enableIcedTea;
        };

        wrapper = pkgs.wrapFirefox.override {
          config = fcfg;
        };
      in
        [ (wrapper cfg.package { }) ];

    home.file.".mozilla/${extensionPath}" = mkIf (cfg.extensions != []) (
      let
        extensionsEnv = pkgs.buildEnv {
          name = "hm-firefox-extensions";
          paths = cfg.extensions;
        };
      in
        {
          source = "${extensionsEnv}/share/mozilla/${extensionPath}";
          recursive = true;
        }
    );
  };
}
