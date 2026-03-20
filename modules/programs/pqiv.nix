{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pqiv;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.maintainers; [
    donovanglover
    iynaix
  ];

  options.programs.pqiv = {
    enable = lib.mkEnableOption "pqiv image viewer";

    package = lib.mkPackageOption pkgs "pqiv" { };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/pqivrc`. See
        {manpage}`pqiv(1)` for a list of available options.
      '';
      example = lib.literalExpression ''
        {
          options = {
            lazy-load = true;
            hide-info-box = true;
            background-pattern = "black";
            thumbnail-size = "256x256";
            command-1 = "thunar";
          };
        };
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra lines to be added to {file}`$XDG_CONFIG_HOME/pqivrc`. See
        {manpage}`pqiv(1)` for a list of available options.
      '';
      example = lib.literalExpression ''
        [actions]
        set_cursor_auto_hide(1)

        [keybindings]
        t { montage_mode_enter() }
        @MONTAGE {
          t { montage_mode_return_cancel() }
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.pqiv" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."pqivrc" = lib.mkIf (cfg.settings != { } || cfg.extraConfig != "") {
      text = lib.concatLines [
        (lib.generators.toINI {
          mkKeyValue =
            key: value:
            let
              value' = if lib.isBool value then (if value then "1" else "0") else toString value;
            in
            "${key} = ${value'}";
        } cfg.settings)
        cfg.extraConfig
      ];
    };
  };
}
