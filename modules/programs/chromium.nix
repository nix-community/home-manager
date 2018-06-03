{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs;

  browserModule = browser: defaultPkg: name: {
    enable = mkEnableOption name;

    package = mkOption {
      type = types.package;
      default = defaultPkg;
      defaultText = "pkgs.${browser}";
      description = "The ${name} package to use.";
    };

    extensions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = literalExample ''
        [
          "chlffgpmiacpedhhbkiomidkjlcfhogd" # pushbullet
          "mbniclmhobmnbdlbpiphghaielnnpgdp" # lightshot
          "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        ]
      '';
      description = ''
        List of ${name} extensions to install.
        To find the extension ID, check its URL on the
        <link xlink:href="https://chrome.google.com/webstore/category/extensions">Chrome Web Store</link>.
      '';
    };
  };

  browserConfig = browser: cfg:
    let
      darwinDirs = {
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        google-chrome-beta = "Google/Chrome Beta";
        google-chrome-dev = "Google/Chrome Dev";
      };

      configDir = if pkgs.stdenv.isDarwin
        then "Library/Application Support/${builtins.getAttr browser darwinDirs}"
        else "${config.xdg.configHome}/${browser}";

      extensionJson = ext: {
        target = "${configDir}/External Extensions/${ext}.json";
        text = builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        };
      };

    in {
      home.packages = [ cfg.package ];
      home.file = map extensionJson cfg.extensions;
    };

in {
  options.programs = {
    chromium = browserModule "chromium" pkgs.chromium "Chromium";
    google-chrome = browserModule "google-chrome" pkgs.google-chrome "Google Chrome";
    google-chrome-beta = browserModule "google-chrome-beta" pkgs.google-chrome-beta "Google Chrome Beta";
    google-chrome-dev = browserModule "google-chrome-dev" pkgs.google-chrome-dev "Google Chrome Dev";
  };

  config = mkMerge [
    (mkIf cfg.chromium.enable (browserConfig "chromium" cfg.chromium))
    (mkIf cfg.google-chrome.enable (browserConfig "google-chrome" cfg.google-chrome))
    (mkIf cfg.google-chrome-beta.enable (browserConfig "google-chrome-beta" cfg.google-chrome-beta))
    (mkIf cfg.google-chrome-dev.enable (browserConfig "google-chrome-dev" cfg.google-chrome-dev))
  ];
}
