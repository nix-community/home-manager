{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.discocss;
in {
  meta.maintainers = with maintainers; [ kranzes ];

  options = {
    programs.discocss = {
      enable = mkEnableOption
        "discocss, a tiny Discord CSS injector for Linux and MacOS";

      package = mkPackageOption pkgs "discocss" { nullable = true; };

      discordPackage = mkPackageOption pkgs "discord" { nullable = true; };

      discordAlias = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to alias discocss to discord.";
      };

      css = mkOption {
        type = types.str;
        default = "";
        description = "The custom CSS for discocss to use.";
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

    home.packages = lib.mkIf (cfg.package != null) [
      (cfg.package.override {
        discordAlias = cfg.discordAlias;
        discord = lib.mkIf (cfg.discordPackage != null) cfg.discordPackage;
      })
    ];

    xdg.configFile."discocss/custom.css".text = cfg.css;
  };
}
