{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.gurk-rs;
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
in
{
  meta.maintainers = [ lib.maintainers.da157 ];

  options.programs.gurk-rs = {
    enable = lib.mkEnableOption "gurk-rs";
    package = lib.mkPackageOption pkgs "gurk-rs" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/.config/gurk/gurk.toml`
        or {file}`Library/Application Support/gurk/gurk.toml`. Options are
        declared at <https://github.com/boxdot/gurk-rs/blob/main/src/config.rs>.
        Note that `signal_db_path` should be set.
      '';
      example = lib.literalExpression ''
        {
          signal_db_path = "/home/USERNAME/.local/share/gurk/signal-db";
          first_name_only = false;
          show_receipts = true;
          notifications = true;
          bell = true;
          colored_messages = false;
          default_keybindings = true;
          user = {
            name = "MYNAME";
            phone_number = "MYNUMBER";
          };
          keybindings =  { };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/gurk/gurk.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "gurk-config" cfg.settings;
    };
  };
}
