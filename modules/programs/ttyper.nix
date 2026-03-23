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

  cfg = config.programs.ttyper;
  tomlFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.ttyper = {
    enable = lib.mkEnableOption "ttyper, a terminal-based typing test";

    package = lib.mkPackageOption pkgs "ttyper" { nullable = true; };

    settings = mkOption {
      type = types.submodule {
        freeformType = tomlFormat.type;

        options = {
          default_language = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "english200";
            description = ''
              Language used when none is manually specified.

              Built-in options: {var}`c`, {var}`csharp`, {var}`english100`,
              {var}`english200`, {var}`english1000`, {var}`english-advanced`,
              {var}`english-pirate`, {var}`french100`, {var}`french200`,
              {var}`french1000`, {var}`german`, {var}`german1000`,
              {var}`german10000`, {var}`go`, {var}`html`, {var}`java`,
              {var}`javascript`, {var}`norwegian`, {var}`php`,
              {var}`portuguese`, {var}`portuguese200`, {var}`portuguese1000`,
              {var}`portuguese-advanced`, {var}`python`, {var}`qt`,
              {var}`ruby`, {var}`rust`, {var}`spanish`, {var}`ukrainian`.

              Custom languages can be added by placing a file with one word
              per line in the ttyper languages config directory.
            '';
          };

          theme = mkOption {
            type = types.nullOr (types.attrsOf types.str);
            default = null;
            description = ''
              Theme configuration for ttyper as a free-form attribute set.

              Keys correspond to ttyper theme fields (e.g. {var}`prompt_correct`,
              {var}`input_border`, {var}`border_type`). Style values are strings
              in the format `fg:bg;modifier1;modifier2`. Colors can be a named
              terminal color, a 6-digit hex code (e.g. {var}`ff0000`),
              {var}`none`, or {var}`reset`.

              See the ttyper documentation for all available theme keys.
            '';
            example = literalExpression ''
              {
                border_type = "rounded";
                input_border = "cyan";
                prompt_border = "green";
                prompt_correct = "green";
                prompt_incorrect = "red";
                prompt_untyped = "gray";
                prompt_current_correct = "green;bold";
                prompt_current_incorrect = "red;bold";
                prompt_current_untyped = "blue;bold";
                prompt_cursor = "none;underlined";
                results_overview = "cyan;bold";
                results_overview_border = "cyan";
                results_worst_keys = "cyan;bold";
                results_worst_keys_border = "cyan";
                results_chart = "cyan";
                results_chart_x = "cyan";
                results_chart_y = "gray;italic";
                results_restart_prompt = "gray;italic";
              }
            '';
          };
        };
      };
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/ttyper/config.toml`.

        See the ttyper documentation for all available options.
      '';
      example = literalExpression ''
        {
          default_language = "english200";
          theme = {
            border_type = "rounded";
            prompt_correct = "green";
            prompt_incorrect = "red";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."ttyper/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "ttyper-config.toml" cfg.settings;
    };
  };
}
