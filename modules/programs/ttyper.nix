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

  colorType = types.either (types.enum [
    "none"
    "reset"
    "black"
    "white"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "gray"
    "darkgray"
    "lightred"
    "lightgreen"
    "lightyellow"
    "lightblue"
    "lightmagenta"
    "lightcyan"
  ]) (types.strMatching "^[0-9a-fA-F]{6}$");

  modifierType = types.enum [
    "bold"
    "crossed_out"
    "dim"
    "hidden"
    "italic"
    "rapid_blink"
    "slow_blink"
    "reversed"
    "underlined"
  ];

  borderType = types.enum [
    "plain"
    "rounded"
    "double"
    "thick"
    "quadrantinside"
    "quadrantoutside"
  ];

  styleModule = types.submodule {
    options = {
      fg = mkOption {
        type = types.nullOr colorType;
        default = null;
        description = "Foreground color.";
      };
      bg = mkOption {
        type = types.nullOr colorType;
        default = null;
        description = "Background color.";
      };
      modifiers = mkOption {
        type = types.listOf modifierType;
        default = [ ];
        example = [
          "bold"
          "italic"
        ];
        description = "Style modifiers to apply.";
      };
    };
  };

  mkStyleOption =
    desc:
    mkOption {
      type = types.nullOr styleModule;
      default = null;
      description = desc;
    };

  styleToString =
    style:
    let
      colorPart =
        if style.fg != null && style.bg != null then
          "${style.fg}:${style.bg}"
        else if style.fg != null then
          style.fg
        else if style.bg != null then
          "none:${style.bg}"
        else
          "none";
      modifierPart = lib.concatStringsSep ";" style.modifiers;
    in
    if modifierPart == "" then colorPart else "${colorPart};${modifierPart}";

  themeModule = types.submodule {
    options = {
      default = mkStyleOption "Default style applied to empty cells and unstyled content.";
      title = mkStyleOption "Title text styling.";

      input_border = mkStyleOption "Input box border styling.";
      prompt_border = mkStyleOption "Prompt box border styling.";
      border_type = mkOption {
        type = types.nullOr borderType;
        default = null;
        description = "Border style for all boxes.";
      };

      prompt_correct = mkStyleOption "Correctly typed words.";
      prompt_incorrect = mkStyleOption "Incorrectly typed words.";
      prompt_untyped = mkStyleOption "Untyped words.";
      prompt_current_correct = mkStyleOption "Correctly typed letters in the current word.";
      prompt_current_incorrect = mkStyleOption "Incorrectly typed letters in the current word.";
      prompt_current_untyped = mkStyleOption "Untyped letters in the current word.";
      prompt_cursor = mkStyleOption "Cursor character styling.";

      results_overview = mkStyleOption "Results overview text.";
      results_overview_border = mkStyleOption "Results overview border.";
      results_worst_keys = mkStyleOption "Worst keys text.";
      results_worst_keys_border = mkStyleOption "Worst keys border.";
      results_chart = mkStyleOption "Results chart default styling, including plotted data.";
      results_chart_x = mkStyleOption "Results chart x-axis label.";
      results_chart_y = mkStyleOption "Results chart y-axis label.";
      results_restart_prompt = mkStyleOption "Restart/quit prompt styling in the results screen.";
    };
  };

  styleFields = [
    "default"
    "title"
    "input_border"
    "prompt_border"
    "prompt_correct"
    "prompt_incorrect"
    "prompt_untyped"
    "prompt_current_correct"
    "prompt_current_incorrect"
    "prompt_current_untyped"
    "prompt_cursor"
    "results_overview"
    "results_overview_border"
    "results_worst_keys"
    "results_worst_keys_border"
    "results_chart"
    "results_chart_x"
    "results_chart_y"
    "results_restart_prompt"
  ];

  themeToAttrs =
    theme:
    let
      serializedStyles = lib.listToAttrs (
        lib.filter (x: x.value != null) (
          map (field: {
            name = field;
            value = if theme.${field} != null then styleToString theme.${field} else null;
          }) styleFields
        )
      );
    in
    serializedStyles // lib.filterAttrs (_: v: v != null) { inherit (theme) border_type; };

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.programs.ttyper = {
    enable = lib.mkEnableOption "ttyper, a terminal-based typing test";

    package = lib.mkPackageOption pkgs "ttyper" { nullable = true; };

    settings = {
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
        type = types.nullOr themeModule;
        default = null;
        description = ''
          Theme configuration for ttyper.

          Each style field accepts an optional foreground color, background
          color, and list of modifiers. Colors can be a named terminal color,
          a 6-digit hex code (e.g. {var}`ff0000`), {var}`none`, or
          {var}`reset`. When null, the entire theme section is omitted.
        '';
        example = literalExpression ''
          {
            border_type = "rounded";
            input_border = { fg = "cyan"; };
            prompt_border = { fg = "green"; };
            prompt_correct = { fg = "green"; };
            prompt_incorrect = { fg = "red"; };
            prompt_untyped = { fg = "gray"; };
            prompt_current_correct = { fg = "green"; modifiers = [ "bold" ]; };
            prompt_current_incorrect = { fg = "red"; modifiers = [ "bold" ]; };
            prompt_current_untyped = { fg = "blue"; modifiers = [ "bold" ]; };
            prompt_cursor = { modifiers = [ "underlined" ]; };
            results_overview = { fg = "cyan"; modifiers = [ "bold" ]; };
            results_overview_border = { fg = "cyan"; };
            results_worst_keys = { fg = "cyan"; modifiers = [ "bold" ]; };
            results_worst_keys_border = { fg = "cyan"; };
            results_chart = { fg = "cyan"; };
            results_chart_x = { fg = "cyan"; };
            results_chart_y = { fg = "gray"; modifiers = [ "italic" ]; };
            results_restart_prompt = { fg = "gray"; modifiers = [ "italic" ]; };
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."ttyper/config.toml" =
      let
        settingsAttrs =
          lib.filterAttrs (_: v: v != null) {
            inherit (cfg.settings) default_language;
          }
          // lib.optionalAttrs (cfg.settings.theme != null) {
            theme = themeToAttrs cfg.settings.theme;
          };
      in
      mkIf (settingsAttrs != { }) {
        source = tomlFormat.generate "ttyper-config.toml" settingsAttrs;
      };
  };
}
