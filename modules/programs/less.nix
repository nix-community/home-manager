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
          in
          attrsOf (either scalar (listOf scalar));
        default = { };
        description = "GNU-style options to be set via {env}`$LESS`.";
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

    programs.less.config = lib.mkIf (cfg.options != { }) (
      let
        color = lib.intersectAttrs {
          color = null;
          D = null;
        } cfg.options;
        prompt = lib.intersectAttrs {
          prompt = null;
          P = null;
        } cfg.options;
        otherOptions = lib.removeAttrs cfg.options [
          "color"
          "D"
          "P"
          "prompt"
        ];

        toCommandLine = lib.cli.toGNUCommandLineShell { };

        orderedOptions = lib.filter (x: x != { }) [
          otherOptions
          color # colors need to come after `--use-color`.
          prompt # the prompt has to be the last option.
        ];
      in
      lib.mkBefore ''
        #env
        LESS = ${lib.concatMapStringsSep " " toCommandLine orderedOptions}
      ''
    );
  };
}
