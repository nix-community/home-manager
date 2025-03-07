{ config, lib, pkgs, ... }:
let toml = pkgs.formats.toml { };
in {
  meta.maintainers = with lib.maintainers; [ HeitorAugustoLN ];

  options.programs.vinegar = {
    enable = lib.mkEnableOption "Vinegar";

    package = lib.mkPackageOption pkgs "vinegar" { };

    settings = lib.mkOption {
      type = lib.types.attrsOf toml.type;
      default = { };
      example = {
        env.WINEFSYNC = "1";

        studio = {
          dxvk = false;
          renderer = "Vulkan";

          fflags.DFIntTaskSchedulerTargetFps = 144;

          env = {
            DXVK_HUD = "0";
            MANGOHUD = "1";
          };
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/vinegar/config.toml`.

        See <https://vinegarhq.org/Configuration/> for more information.
      '';
    };
  };

  config = let cfg = config.programs.vinegar;
  in lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.vinegar" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."vinegar/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = toml.generate "vinegar-config.toml" cfg.settings;
    };
  };
}
