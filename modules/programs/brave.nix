{ config, lib, pkgs, ... }:

with lib;

let

  browserModule = defaultPkg: name: visible:
    let browser = (builtins.parseDrvName defaultPkg.name).name;
    in {
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
        default = [ ];
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

      browser = "Brave-Browser";

      configDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support/${vendor}/${browser}"
      else
        "${config.xdg.configHome}/${vendor}/${browser}";

      extensionJson = ext: {
        name = "${configDir}/External Extensions/${ext}.json";
        value.text = builtins.toJSON {
          external_update_url =
            "https://clients2.google.com/service/update2/crx";
        };
      };

      vendor = "BraveSoftware";

    in mkIf cfg.enable {
      home.packages = [ cfg.package ];
      home.file = listToAttrs (map extensionJson cfg.extensions);
    };

in {
  meta.maintainers = [ maintainers.farlion ];

  options.programs = { brave = browserModule pkgs.brave "Brave Browser" true; };

  config = mkMerge [ (browserConfig config.programs.brave) ];
}
