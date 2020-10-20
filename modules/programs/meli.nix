{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.meli;
  settingsFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.colemickens ];

  options.programs.meli = {
    enable = mkEnableOption "meli";

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = ''
        meli's settings (will be converted to TOML)
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.meli ];

    xdg.configFile."meli/config.toml".source =
      (settingsFormat.generate "meli-config.toml" cfg.settings);
  };
}
