{ config, lib, pkgs, ... }:

with lib;

let

  browserModule = defaultPkg: name: visible:
    let
      browser = (builtins.parseDrvName defaultPkg.name).name;
    in
      {
        enable = mkOption {
          inherit visible;
          default = false;
          example = true;
          description = "Whether to enable ${name}.";
          type = lib.types.bool;
        };

        package = mkOption {
          inherit visible;
          type = types.package;
          default = defaultPkg;
          defaultText = literalExample "pkgs.${browser}";
          description = "The ${name} package to use.";
        };

        extensions = mkOption {
          inherit visible;
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

  browserConfig = cfg:
    let

      browser = (builtins.parseDrvName cfg.package.name).name;

      darwinDirs = {
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        google-chrome-beta = "Google/Chrome Beta";
        google-chrome-dev = "Google/Chrome Dev";
      };

      configDir = if pkgs.stdenv.isDarwin
        then "Library/Application Support/${getAttr browser darwinDirs}"
        else "${config.xdg.configHome}/${browser}";

      extensionJson = ext: {
        target = "${configDir}/External Extensions/${ext}.json";
        text = builtins.toJSON {
          external_update_url = "https://clients2.google.com/service/update2/crx";
        };
      };

    in
      mkIf cfg.enable {
        home.packages = [ cfg.package ];
        home.file = map extensionJson cfg.extensions;
      };

in

{
  options.programs = {
    chromium = browserModule pkgs.chromium "Chromium" true;
    google-chrome = browserModule pkgs.google-chrome "Google Chrome" false;
    google-chrome-beta = browserModule pkgs.google-chrome-beta "Google Chrome Beta" false;
    google-chrome-dev = browserModule pkgs.google-chrome-dev "Google Chrome Dev" false;
  };

  config = mkMerge [
    (browserConfig config.programs.chromium)
    (browserConfig config.programs.google-chrome)
    (browserConfig config.programs.google-chrome-beta)
    (browserConfig config.programs.google-chrome-dev)
  ];
}
