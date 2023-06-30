{ config, lib, pkgs, ... }:

let
  cfg = config.programs.comodoro;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = with lib.hm.maintainers; [ soywod ];

  options.programs.comodoro = {
    enable =
      lib.mkEnableOption (lib.mdDoc "Comodoro, a CLI to manage your time");

    package = lib.mkPackageOptionMD pkgs "comodoro" { };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = lib.mdDoc ''
        Comodoro configuration.
        See <https://pimalaya.org/comodoro/cli/configuration/> for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."comodoro/config.toml".source =
      tomlFormat.generate "comodoro-config.toml" cfg.settings;
  };
}
