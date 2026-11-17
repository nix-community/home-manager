{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tuios;
  tomlFormat = pkgs.formats.toml { };
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin && !config.xdg.enable then
      "Library/Application Support"
    else
      config.xdg.configHome;
in
{
  meta.maintainers = [ lib.maintainers.hmajid2301 ];

  options.programs.tuios = {
    enable = lib.mkEnableOption "TUIOS terminal window manager";

    package = lib.mkPackageOption pkgs "tuios" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        appearance.theme = "catppuccin_mocha";
        keybindings.preset = "tmux";
        startup.tiled = true;
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/tuios/config.d/10-home-manager.toml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/tuios/config.d/10-home-manager.toml`.

        TUIOS reads drop-ins in name order, then applies {file}`config.toml`
        last. Settings saved interactively may therefore override these
        defaults. Home Manager leaves {file}`config.toml` unmanaged so that
        TUIOS can save changes without writing to the Nix store.

        See <https://github.com/Gaurav-Gosain/tuios/blob/main/docs/CONFIGURATION.md>
        for supported settings and configuration precedence.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/tuios/config.d/10-home-manager.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "tuios-defaults.toml" cfg.settings;
    };
  };
}
