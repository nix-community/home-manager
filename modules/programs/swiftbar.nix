{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.swiftbar;

  refreshRateSuffixes = [ "ms" "s" "m" "h" "d" ];
  validateRefreshRate = value:
    (builtins.match "[0-9]+[${concatStringsSep "|" refreshRateSuffixes}]+"
      value) != null;

  metaAttrs = [ "swiftbar" "bitbar" ];
  validateMetaAttrs = value:
    (builtins.match (concatStringsSep "|" metaAttrs) value) != null;

  # The interval a plugin refreshes at is defined by its filename. Create a bash script with the
  # appropriate filename and metadata for each plugin, which executes the user-provided script.
  mkPlugin = plugin:
    let
      format = value:
        if isBool value then if value then "true" else "false" else value;

      meta = concatStringsSep "\n" (mapAttrsToList (sectionName: attrs:
        concatStringsSep "\n" (map (attrName:
          let
            key = "${sectionName}.${attrName}";
            value = format attrs.${attrName};
          in "# <${key}>${value}</${key}>") (attrNames attrs))) plugin.meta);

      text = optionalString (plugin.meta != { }) (meta + "\n") + plugin.plugin;
    in pkgs.writeShellScriptBin "${plugin.name}.${plugin.refreshRate}.sh" text;

  joinedPlugins = pkgs.symlinkJoin {
    name = "swiftbar-plugins";
    paths = map (plugin: mkPlugin plugin) cfg.plugins;
  };

  # The plugin directory can only be set by writing to the preferences plist, which we
  # want to do prior to starting swiftbar. This script is used in the launchd service.
  swiftbarWithPlugins = pkgs.writeShellScriptBin "start-swiftbar-service" ''
    defaults write com.ameba.SwiftBar PluginDirectory ${joinedPlugins}/bin
    ${cfg.package}/bin/SwiftBar
  '';
in {
  meta.maintainers = with maintainers; [ ivar ];

  options.programs.swiftbar = {
    enable = mkEnableOption "Swiftbar";

    package = mkOption {
      type = types.package;
      default = pkgs.swiftbar;
      defaultText = literalExpression "pkgs.swiftbar";
      description = "Swiftbar package to use.";
    };

    plugins = mkOption {
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "foo";
            refreshRate = "100ms";
            plugin = pkgs.writeShellScript "foo" "echo bar";
            meta.bitbar = {
              version = "v1.0";
              desc = "Example description";
            };
          }
        ]
      '';
      description = ''
        The plugins to install.
      '';

      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "foo";
            description = ''
              The name of the plugin.
            '';
          };

          plugin = mkOption {
            type = types.path;
            example = literalExpression ''
              pkgs.writeShellScript "foo" "echo foo"
            '';
            description = ''
              Path to the plugin to execute. This can be any script printing to
              standard output. See <link xlink:href="https://github.com/swiftbar/SwiftBar#script-output"/>.
            '';
          };

          refreshRate = mkOption {
            type = types.addCheck types.str (value: validateRefreshRate value)
              // {
                description = "number ending with '${
                    concatStringsSep "' or '" refreshRateSuffixes
                  }'";
              };
            example = "100ms";
            description = ''
              The interval to refresh the plugin at.
            '';
          };

          meta = mkOption {
            type = with types;
              addCheck (attrsOf (attrsOf (either bool str))) (value:
                builtins.all (v: v)
                (map (name: validateMetaAttrs name) (attrNames value))) // {
                  description = "attrset named '${
                      concatStringsSep "' or '" metaAttrs
                    }' containing bool or string";
                };
            default = { };
            example = literalExpression ''
              {
                bitbar.title = "My menu bar plugin";
                swiftbar.hideRunInTerminal = true;
              }
            '';
            description = ''
              Metadata to be added to the plugin.
              See <link xlink:href="https://github.com/swiftbar/SwiftBar#script-metadata"/>.
            '';
          };
        };
      });
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.swiftbar" pkgs platforms.darwin)
    ];

    launchd.agents.swiftbar = {
      enable = true;
      config = {
        ProgramArguments = toList (if (cfg.plugins != [ ]) then
          "${swiftbarWithPlugins}/bin/start-swiftbar-service"
        else
          cfg.package.outPath);
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };

    home.packages = if (cfg.plugins != [ ]) then [
      swiftbarWithPlugins
      cfg.package
    ] else
      toList cfg.package;
  };
}
