{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.sioyek;

  renderConfig = lib.generators.toKeyValue {
    mkKeyValue = key: value: "${key} ${value}";
    listsAsDuplicateKeys = true;
  };
in
{
  meta.maintainers = [ lib.maintainers.podocarp ];

  options = {
    programs.sioyek = {
      enable = lib.mkEnableOption "Sioyek, a PDF viewer designed for reading research papers and technical books";

      package = lib.mkPackageOption pkgs "sioyek" { };

      bindings = mkOption {
        description = ''
          Input configuration written to
          {file}`$XDG_CONFIG_HOME/sioyek/keys_user.config`.
          See <https://github.com/ahrm/sioyek/blob/main/pdf_viewer/keys.config>.

          Each attribute could also accept a list of strings to set multiple
          bindings of the same command.
        '';
        type = with types; attrsOf (either str (listOf str));
        default = { };
        example = literalExpression ''
          {
            "move_up" = "k";
            "move_down" = "j";
            "move_left" = "h";
            "move_right" = "l";
            "screen_down" = [ "d" "<C-d>" ];
            "screen_up" = [ "u" "<C-u>" ];
          }
        '';
      };

      config = mkOption {
        description = ''
          Input configuration written to
          {file}`$XDG_CONFIG_HOME/sioyek/prefs_user.config`.
          See <https://github.com/ahrm/sioyek/blob/main/pdf_viewer/prefs.config>.
        '';
        default = { };
        example = literalExpression ''
          {
            "background_color" = "1.0 1.0 1.0";
            "text_highlight_color" = "1.0 0.0 0.0";
            startup_commands = [
              "toggle_visual_scroll"
              "toggle_dark_mode"
            ];
          }
        '';
        type = types.submodule {
          freeformType = types.attrsOf types.str;

          options.startup_commands = mkOption {
            description = ''
              Commands to be run upon startup. Will be written to {file}`$XDG_CONFIG_HOME/sioyek/prefs_user.config`.
              See <https://github.com/ahrm/sioyek/blob/a4ce95fd968804fbf6ff3befcbe0d9b972bd754c/pdf_viewer/prefs.config#L116>.
            '';
            type = types.either types.str (types.listOf types.str);
            apply =
              x:
              lib.warnIf (lib.isString x)
                "`programs.sioyek.config.startup_commands` should now be a list of strings instead of a string."
                x;
            default = [ ];
            example = [
              "toggle_visual_scroll"
              "toggle_dark_mode"
            ];
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (
    let
      prefsCfg =
        cfg.config
        //
          lib.optionalAttrs (cfg.config.startup_commands != [ ] && !lib.isString cfg.config.startup_commands)
            {
              startup_commands = lib.concatStringsSep ";" cfg.config.startup_commands;
            };
    in
    lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }
      (mkIf (prefsCfg != { }) {
        xdg.configFile."sioyek/prefs_user.config".text = renderConfig prefsCfg;
      })
      (mkIf (cfg.bindings != { }) {
        xdg.configFile."sioyek/keys_user.config".text = renderConfig cfg.bindings;
      })
    ]
  );
}
