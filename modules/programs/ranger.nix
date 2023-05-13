{ config, lib, pkgs, ... }:
with lib;
let cfg = config.programs.ranger;
in {
  options = {
    programs.ranger = {
      enable =
        mkEnableOption "ranger is a console file manager with VI key bindings.";

      package = mkOption {
        default = pkgs.ranger;
        defaultText = literalExpression "pkgs.ranger";
        type = types.package;
        description = "Package providing the ranger binary";
      };

      extraPackages = mkOption {
        default = [ ];
        defaultText = literalExpression "[ ueberzug ]";
        type = types.listOf types.package;
        description = "Extra packages available to ranger.";
      };

      config = mkOption {
        description = ''
          Startup configuration file written to
          <filename>$XDG_CONFIG_HOME/ranger/rc.conf</filename>.
          See <link xlink:href="https://github.com/ranger/ranger/blob/master/ranger/config/rc.conf"/>.
        '';
        type = types.nullOr types.path;
        default = null;
      };

      commands = mkOption {
        description = ''
          Commands configuration file written to
          <filename>$XDG_CONFIG_HOME/ranger/commands.py</filename>.
          See <link xlink:href="https://github.com/ranger/ranger/blob/master/ranger/config/commands.py"/>.
        '';
        type = types.nullOr types.path;
        default = null;
      };

      rifle = mkOption {
        description = ''
          File launcher configuration file written to
          <filename>$XDG_CONFIG_HOME/ranger/rifle.conf</filename>.
          See <link xlink:href="https://github.com/ranger/ranger/blob/master/ranger/config/rifle.conf"/>.
        '';
        type = types.nullOr types.path;
        default = null;
      };

      scope = mkOption {
        description = ''
          File preview configuration file written to
          <filename>$XDG_CONFIG_HOME/ranger/scope.sh</filename>.
          See <link xlink:href="https://github.com/ranger/ranger/blob/master/ranger/data/scope.sh"/>.
        '';
        type = types.nullOr types.path;
        default = null;
      };

      loadDefaultRc = mkOption {
        description = ''
          Value of the environment variable RANGER_LOAD_DEFAULT_RC.
          Set it to false to not load the default built-in ranger configs.
        '';
        type = types.bool;
        default = true;
        example = false;
      };

      plugins = mkOption {
        description = ''
          List of files to be written to
          <filename>$XDG_CONFIG_HOME/ranger/plugins/</filename>.
          See <link xlink:href="https://github.com/ranger/ranger/wiki/Plugins"/>.
        '';
        type = let
          pluginType = types.submodule ({ name, ... }: {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
              };
              path = mkOption { type = types.path; };
            };
          });
        in types.listOf pluginType;
        default = [ ];
        example = literalExpression ''
          [
            {
              name = "ranger_devicons";
              path = builtins.fetchGit "https://github.com/alexanderjeurissen/ranger_devicons";
            }
          ]
        '';
      };
    };
  };

  config = let
    pluginToAttrList = p: {
      name = "ranger/plugins/${p.name}";
      value.source = p.path;
    };
    rangerPackage = cfg.package.overrideAttrs (super: {
      propagatedBuildInputs = super.propagatedBuildInputs ++ cfg.extraPackages;
    });
  in mkIf cfg.enable (mkMerge [
    {
      home.packages = [ rangerPackage ];
      home.sessionVariables."RANGER_LOAD_DEFAULT_RC" = cfg.loadDefaultRc;
    }
    (mkIf (cfg.config != null) {
      xdg.configFile."ranger/rc.conf".source = cfg.config;
    })
    (mkIf (cfg.commands != null) {
      xdg.configFile."ranger/commands.py".source = cfg.commands;
    })
    (mkIf (cfg.rifle != null) {
      xdg.configFile."ranger/rifle.conf".source = cfg.rifle;
    })
    (mkIf (cfg.scope != null) {
      xdg.configFile."ranger/scope.sh" = {
        source = cfg.scope;
        executable = true;
      };
    })
    (mkIf (cfg.plugins != [ ]) {
      xdg.configFile = (listToAttrs (map pluginToAttrList cfg.plugins));
    })
  ]);

  meta.maintainers = [ hm.maintainers.podocarp ];
}
