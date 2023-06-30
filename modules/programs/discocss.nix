{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.discocss;
in {
  meta.maintainers = with maintainers; [ kranzes ];

  options = {
    programs.discocss = {
      enable = mkEnableOption
        (lib.mdDoc "discocss, a tiny Discord CSS injector for Linux and MacOS");

      package = mkPackageOptionMD pkgs "discocss" { };

      discordPackage = mkPackageOptionMD pkgs "discord" { };

      discordAlias = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether to alias discocss to discord.";
      };

      css = mkOption {
        type = types.str;
        default = "";
        description = lib.mdDoc "The custom CSS for discocss to use.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.discordAlias
        -> !(any (p: p.name == cfg.discordPackage.name) config.home.packages);
      message =
        "To use discocss with discordAlias you have to remove discord from home.packages, or set discordAlias to false.";
    }];

    home.packages = [
      (cfg.package.override {
        discordAlias = cfg.discordAlias;
        discord = cfg.discordPackage;
      })
    ];

    xdg.configFile."discocss/custom.css".text = cfg.css;
  };
}
