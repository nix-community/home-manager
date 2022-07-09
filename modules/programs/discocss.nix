{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.discocss;

  discocssWrapper = { stdenvNoCC, fetchFromGitHub, lib, makeWrapper, runCommand
    , discocss, discord, alias ? false }:
    runCommand "discocss" {
      buildInputs = [ makeWrapper ];
      preferLocalBuild = true;
    } ''
      mkdir -p $out/{bin,share}

      ${lib.optionalString alias ''
        ln -s $out/bin/discocss $out/bin/Discord
        ln -s ${discord}/share/* $out/share/
      ''}

      makeWrapper ${discocss}/bin/discocss $out/bin/discocss \
        --set DISCOCSS_DISCORD_BIN ${discord}/bin/Discord
    '';
in {
  meta.maintainers = with maintainers; [ fufexan ];

  options = {
    programs.discocss = {
      enable = mkEnableOption "discocss";

      package = mkOption {
        type = types.package;
        default = pkgs.callPackage discocssWrapper { };
        description = ''
          Package to use for Discocss.
        '';
      };

      discordPackage = mkOption {
        type = types.package;
        default = pkgs.discord;
        description = ''
          Discord package to apply Discocss to.
        '';
      };

      alias = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to alias the <code>Discord</code> command to <code>discocss</code>.
        '';
      };

      css = mkOption {
        type = types.str;
        default = "";
        description = ''
          Custom CSS to theme Discord.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.alias
        -> !(builtins.any (p: p.name == cfg.discordPackage.name)
          config.home.packages);
      message =
        "To use discocss with alias you have to remove discord from home.packages, or set alias = false;";
    }];

    home.packages = [
      (cfg.package.override {
        inherit (cfg) alias;
        discord = cfg.discordPackage;
      })
    ];

    xdg.configFile."discocss/custom.css".text = cfg.css;
  };
}
