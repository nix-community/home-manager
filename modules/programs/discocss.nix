{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.discocss;
in
{
  meta.maintainers = with lib.maintainers; [ kranzes ];

  options = {
    programs.discocss = {
      enable = lib.mkEnableOption "discocss, a tiny Discord CSS injector for Linux and MacOS";

      package = lib.mkPackageOption pkgs "discocss" { nullable = true; };

      discordPackage = lib.mkPackageOption pkgs "discord" { nullable = true; };

      discordAlias = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to alias discocss to discord.";
      };

      css = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The custom CSS for discocss to use.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.discordAlias -> !(lib.any (p: p.name == cfg.discordPackage.name) config.home.packages);
        message = "To use discocss with discordAlias you have to remove discord from home.packages, or set discordAlias to false.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [
      (cfg.package.override {
        discordAlias = cfg.discordAlias;
        discord = lib.mkIf (cfg.discordPackage != null) cfg.discordPackage;
      })
    ];

    xdg.configFile."discocss/custom.css".text = cfg.css;
  };
}
