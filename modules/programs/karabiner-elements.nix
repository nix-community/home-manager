{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.karabiner-elements;
  # Define the settings format used for this program
  settingsFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.programs.karabiner-elements = {
    enable = lib.mkEnableOption "karabiner-elements";

    package = lib.mkPackageOption pkgs "karabiner-elements" {
      nullable = true;
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = settingsFormat.type;
      };

      default = { };

      description = ''
        Configuration for Karabiner-Elements, see
        <link xlink:href="https://karabiner-elements.pqrs.org/docs/json/"/>
        for supported values.
      '';
    };

  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.karabiner-elements" pkgs lib.platforms.darwin)
    ];

    xdg.configFile."karabiner/karabiner.json".source =
      settingsFormat.generate "karabiner.json" cfg.settings;
  };
}
