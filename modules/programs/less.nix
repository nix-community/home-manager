{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.less;
in
{
  meta.maintainers = [ lib.maintainers.pamplemousse ];

  imports = [
    (lib.mkRenamedOptionModule [ "programs" "less" "keys" ] [ "programs" "less" "config" ])
  ];

  options = {
    programs.less = {
      enable = lib.mkEnableOption "less, opposite of more";

      package = lib.mkPackageOption pkgs "less" { nullable = true; };

      config = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          #command
          s        back-line
          t        forw-line
        '';
        description = ''
          Configuration for {command}`less`, written to
          {file}`$XDG_CONFIG_HOME/lesskey`.
        '';
      };

      options = lib.mkOption {
        type =
          with lib.types;
          let
            scalar = oneOf [
              bool
              int
              str
            ];
            attrs = attrsOf (either scalar (listOf scalar));
          in
          coercedTo attrs (lib.cli.toGNUCommandLine { }) (listOf str);
        default = [ ];
        description = "Options to be set via {env}`$LESS`.";
        example = {
          RAW-CONTROL-CHARS = true;
          quiet = true;
          wheel-lines = 3;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."lesskey" = lib.mkIf (cfg.config != "") { text = cfg.config; };

    programs.less.config = lib.mkIf (cfg.options != [ ]) (
      lib.mkBefore ''
        #env
        LESS = ${lib.concatStringsSep " " cfg.options}
      ''
    );
  };
}
