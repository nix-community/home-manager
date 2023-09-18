{ config, lib, pkgs, ... }:
with lib;
with types;
let cfg = config.programs.bumblebee-status;
in {
  meta.maintainers = with lib.maintainers; [ augustebaum ];

  options.programs.bumblebee-status = {
    enable = mkEnableOption
      "a modular, theme-able status line generator for the i3 window manager";

    plugins = let
      plugin = submodule {
        options = {
          name = mkOption {
            type = str;
            description = "Name of the plugin.";
            example = "memory";
          };

          alias = mkOption {
            type = nullOr str;
            description =
              "Alias to refer to this plugin with. This allows for using plugins more than once, as described in <https://bumblebee-status.readthedocs.io/en/main/introduction.html?highlight=aliases#usage>.";
            default = null;
          };

          parameters = mkOption {
            type = attrs;
            description =
              "Parameters to run the plugin with. See <https://bumblebee-status.readthedocs.io/en/main/features.html#advanced-usage> for explanations and showcase of the available parameters.";
            default = { };
            example = literalExpression ''
              {
                interval = "2m30s";
                left-click = "nautilus {instance}";
                theme.minwidth = "10,10,10,10";
                scrolling.bounce = true;
              }
            '';
          };

          autohide = mkOption {
            type = bool;
            description = ''
              Whether to hide the plugin by default, only showing it when its state is "warning" or "error". See <https://bumblebee-status.readthedocs.io/en/main/features.html#automatically-hiding-modules> for more information.'';
            default = false;
          };

          errorhide = mkOption {
            type = bool;
            description =
              ''Whether to hide the plugin when its state is "error".'';
            default = false;
          };
        };
      };
    in mkOption {
      # NOTE: Needs to be a list to preserve the order
      type = listOf plugin;
      # FIXME: I would shorten the alias explanation since there is an option for it (opt.plugins.*.alias), but I can't figure out how to use the `opt` stuff to refer to it since it is in a list.
      description = ''
        List of plugins to use.
        The plugins will appear on the bar from left to right, except if ${opt.parameters.right-to-left} is used.
        Note that a plugin can be used more than once using the alias mechanic described in <https://bumblebee-status.readthedocs.io/en/main/introduction.html?highlight=aliased#usage>.
        See <https://bumblebee-status.readthedocs.io/en/main/modules.html> for the list of available plugins (or "modules").
      '';
      default = [ ];
      example = literalExpression ''
        [
          { name = "memory"; }
          {
            name = "battery";
            parameters = {
              interval = "2m30s";
              left-click = "nautilus {instance}";
              theme.minwidth = "10,10,10,10";
              scrolling.bounce = true;
            };
          }
        ]
      '';
    };

    right-to-left = mkOption {
      type = bool;
      description = "Whether to display plugins from right to left.";
      default = false;
    };

    theme = mkOption {
      type = str;
      description =
        "Theme to use. See <https://bumblebee-status.readthedocs.io/en/main/themes.html> for the list of available themes.";
      default = "default";
      example = "gruvbox";
    };

    interval = mkOption {
      type = either ints.positive str;
      description =
        "Global refresh interval. Either an integer which will be converted to seconds, or a string with units. See <https://bumblebee-status.readthedocs.io/en/main/features.html#intervals> for more information. Note that a plugin's refresh interval cannot be smaller than this interval.";
      default = 1; # second
      example = "3m";
    };

    package = mkOption {
      type = package;
      default = pkgs.bumblebee-status;
      defaultText = literalExpression "pkgs.bumblebee-status";
      description = "The bumblebee-status package to use.";
    };
  };

  config = mkIf cfg.enable (let
    # getNames :: [Plugin] -> [string]
    getNames = lib.attrsets.catAttrs "name";

    # join :: [string] -> string
    join = builtins.concatStringsSep ",";

    pluginNames = getNames cfg.plugins;

    autohide = join (getNames (builtins.filter (p: p.autohide) cfg.plugins));
    errorhide = join (getNames (builtins.filter (p: p.errorhide) cfg.plugins));

    # getModuleName :: Plugin -> string
    getModuleName = p:
      if (p.alias == null) then p.name else "${p.name}:${p.alias}";

    modules = join (map getModuleName cfg.plugins);

    # mkModuleParameters :: Plugin -> {string: PluginParameters}
    mkModuleParameters = p:
      let moduleId = if (p.alias == null) then p.name else p.alias;
      in { "${moduleId}" = p.parameters; };

    # mergeParameters :: [AttrSet] -> AttrSet
    mergeParameters = lib.lists.fold lib.trivial.mergeAttrs { };

    filterEmpty = lib.attrsets.filterAttrs (_: v: v != { });

    # flattenAttrs :: string -> AttrSet -> AttrSet
    # flattenAttrs "." { a = { b = { c = 1; }; }; } => { "a.b.c" = 1; }
    flattenAttrs = sep: x:
      let
        f = path:
          lib.attrsets.foldlAttrs (acc: name: value:
            (if builtins.isAttrs value then
              (f "${path}${name}${sep}" value)
            else {
              "${path}${name}" = value;
            }) // acc) { };
      in f "" x;

    module-parameters = flattenAttrs "."
      (filterEmpty (mergeParameters (map mkModuleParameters cfg.plugins)));
  in {
    assertions = let
      aliases =
        filter (x: x != null) (lib.attrsets.catAttrs "alias" cfg.plugins);

      # findDuplicates :: [a] -> [a]
      findDuplicates = xs:
        let
          # helper :: [a] -> {seen: [a]; duplicates: [a]}
          helper = foldl (acc: v: {
            seen = acc.seen ++ [ v ];
            duplicates = if elem v acc.seen then
              acc.duplicates ++ [ v ]
            else
              acc.duplicates;
          }) {
            seen = [ ];
            duplicates = [ ];
          };
        in lib.lists.unique (helper xs).duplicates;

      duplicateAliases = findDuplicates aliases;

      prettyPrintList = xs:
        let wrapInQuotes = map (s: ''"${s}"'');
        in "[ " + (concatStringsSep ", " (wrapInQuotes xs)) + " ]";

      intersectionAliasesPluginNames = intersectLists aliases pluginNames;
    in [
      {
        assertion = duplicateAliases == [ ];
        message =
          "No two plugin aliases can be the same. List of offending aliases is: ${
            prettyPrintList duplicateAliases
          }.";
      }
      {
        assertion = intersectionAliasesPluginNames == [ ];
        message =
          "No plugin alias can be the same as a plugin name. List of offending names is: ${
            prettyPrintList intersectionAliasesPluginNames
          }.";
      }
    ];

    home.packages = [ (cfg.package.override { withPlugins = pluginNames; }) ];

    xdg.configFile."bumblebee-status/config" = {
      text = let
        generateINI = generators.toINI {
          mkKeyValue = generators.mkKeyValueDefault { } " = ";
        };
      in generateINI {
        core = {
          inherit modules autohide errorhide;
          inherit (cfg) theme right-to-left interval;
        };
        inherit module-parameters;
      };
    };
  });
}
