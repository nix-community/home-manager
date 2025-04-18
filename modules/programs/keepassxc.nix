{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.keepassxc;

  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = [ lib.maintainers.d-brasher ];

  options.programs.keepassxc = {
    enable = lib.mkEnableOption "keepassxc";

    package = lib.mkPackageOption pkgs "keepassxc" { nullable = true; };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          Browser.Enabled = true;

          GUI = {
            AdvancedSettings = true;
            ApplicationTheme = "dark";
            CompactMode = true;
            HidePasswords = true;
          };

          SSHAgent.Enabled = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/keepassxc/keepassxc.ini`.

        See <https://github.com/keepassxreboot/keepassxc/blob/647272e9c5542297d3fcf6502e6173c96f12a9a0/src/core/Config.cpp#L49-L223>
        for the full list of options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = {
      "keepassxc/keepassxc.ini" = lib.mkIf (cfg.settings != { }) {
        source = iniFormat.generate "keepassxc-settings" cfg.settings;
      };
    };
  };
}
