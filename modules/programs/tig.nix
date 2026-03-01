{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    literalExpression
    concatStringsSep
    mapAttrsToList
    flatten
    removeSuffix
    filter
    optionalString
    map
    ;

  inherit (lib.strings) replaceStrings;

  cfg = config.programs.tig;

  sanitizeString = replaceStrings [ "\n" ''"'' ] [ "\\n" ''\"'' ];

  formatValue =
    v:
    if lib.isBool v then
      (if v then "true" else "false")
    else if lib.isString v then
      ''"${sanitizeString v}"''
    else
      toString v;

  formatSettings =
    settings:
    concatStringsSep "\n" (mapAttrsToList (name: value: "set ${name} = ${formatValue value}") settings);

  formatBindings =
    bindings:
    concatStringsSep "\n" (
      flatten (
        mapAttrsToList (
          keymap: keys:
          mapAttrsToList (
            key: action: "bind ${sanitizeString keymap} ${sanitizeString key} ${sanitizeString action}"
          ) keys
        ) bindings
      )
    );

  formatColors =
    colors:
    concatStringsSep "\n" (
      mapAttrsToList (area: style: "color ${sanitizeString area} ${sanitizeString style}") colors
    );

  formatSources =
    sources: concatStringsSep "\n" (map (path: "source ${sanitizeString path}") sources);

  trimmedExtraConfig = removeSuffix "\n" cfg.extraConfig;

  configContent = concatStringsSep "\n" (
    filter (s: s != "") [
      (optionalString (cfg.settings != { }) (formatSettings cfg.settings))
      (optionalString (cfg.bindings != { }) (formatBindings cfg.bindings))
      (optionalString (cfg.colors != { }) (formatColors cfg.colors))
      (optionalString (cfg.sources != [ ]) (formatSources cfg.sources))
      trimmedExtraConfig
    ]
  );

  generatedConfig = if configContent != "" then configContent + "\n" else "";
in
{
  meta.maintainers = [ lib.hm.maintainers.takeokunn ];

  options.programs.tig = {
    enable = mkEnableOption "tig, a text-mode interface for Git";

    package = lib.mkPackageOption pkgs "tig" { };

    settings = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      default = { };
      example = literalExpression ''
        {
          show-author = "abbreviated";
          show-date = "relative";
          show-rev-graph = true;
          mouse = true;
          tab-size = 4;
          ignore-case = true;
          wrap-lines = true;
          line-graphics = "utf-8";
        }
      '';
      description = ''
        Configuration settings written to the tig config file.
        These are rendered as `set name = value` lines.
        See {manpage}`tigrc(5)` for available options.
      '';
    };

    bindings = mkOption {
      type = with types; attrsOf (attrsOf str);
      default = { };
      example = literalExpression ''
        {
          generic = {
            g = "move-first-line";
            G = "move-last-line";
          };
          main = {
            C = "!git cherry-pick %(commit)";
            "!" = "!git revert %(commit)";
          };
          diff = {
            "<Ctrl-f>" = "scroll-page-down";
            "<Ctrl-b>" = "scroll-page-up";
          };
        }
      '';
      description = ''
        Key bindings written to the tig config file.
        The attribute names are keymaps (generic, main, diff, log, etc.),
        and the values are attribute sets mapping keys to actions.
        These are rendered as `bind keymap key action` lines.
        See {manpage}`tigrc(5)` for available keymaps and actions.
      '';
    };

    colors = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          cursor = "yellow red bold";
          title-blur = "white blue";
          title-focus = "white blue bold";
          diff-header = "yellow default";
          diff-chunk = "magenta default";
        }
      '';
      description = ''
        Color settings written to the tig config file.
        The attribute names are color areas, and the values are
        color specifications (foreground, background, and optional attributes).
        These are rendered as `color area fgcolor bgcolor [attributes]` lines.
        See {manpage}`tigrc(5)` for available color areas.
      '';
    };

    sources = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''
        [
          "~/.tigrc.d/colors.tigrc"
          "~/.tigrc.d/bindings.tigrc"
        ]
      '';
      description = ''
        List of additional tig configuration files to source.
        These are rendered as `source path` lines.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        '''
        # Custom git integration
        bind main R !git rebase -i %(commit)^
        bind main F !git fetch
        bind main P !git push
        '''
      '';
      description = ''
        Extra lines to append to the tig configuration file.
        This is useful for configuration that doesn't fit into
        the structured options above.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."tig/config" = lib.mkIf (generatedConfig != "") {
      text = generatedConfig;
    };
  };
}
