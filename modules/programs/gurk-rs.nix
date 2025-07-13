{
  lib,
  pkgs,
  config,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  cfg = config.programs.gurk-rs;
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

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
        Note that `data_path` and `signal_db_path` should be set.
      '';
      example = lib.literalExpression ''
        {
          data_path = "/home/USERNAME/.local/share/gurk/gurk.data.json";
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
    home.package = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${
      if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome
    }/gurk/gurk.toml".source =
      lib.mkIf (cfg.settings != { }) (tomlFormat.generate "gurk-config" cfg.settings);
  };
}
