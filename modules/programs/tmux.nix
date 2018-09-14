{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.tmux;

  mkChildPackageType = name:
    types.submodule {
      options = {
        enable = mkEnableOption name;

        package = mkOption {
          type = types.package;
          default = pkgs.${name};
          defaultText = "pkgs.${name}";
          description = "Also install ${name}.";
        };
      };
    };

  tmuxinatorModule = mkChildPackageType "tmuxinator";

  tmuxpModule = mkChildPackageType "tmuxp";

  pluginName = p: if types.package.check p then p.name else p.plugin.name;

  pluginModule = types.submodule {
    options = {
      plugin = mkOption {
        type = types.package;
        description = "Path of the configuration file to include.";
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration for the associated plugin.";
        default = "";
      };
    };
  };
in
{
  options = {

    programs.tmux = {
      enable = mkEnableOption "Tmux";

      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        defaultText = "pkgs.tmux";
        example = literalExample "pkgs.tmux";
        description = "tmux";
      };

      sensibleOnTop = mkOption {
        type = types.bool;
        default = true;
        description = "run the sensible plugin at the top of your .conf (this allows you to overwrite sensible configs)";
      };

      tmuxp = mkOption {
        type = tmuxpModule;
        default = {};
        description = "Options to configure Tmuxp";
      };

      tmuxinator = mkOption {
        type = tmuxinatorModule;
        default = {};
        description = "Options to configure Tmuxinator";
      };

      plugins = mkOption {
        type = types.listOf (types.either types.package pluginModule);
        description = ''
          List of tmux plugins to be included at the end of your .tmux.conf
          (the sensible plugin, however, is defaulted to run at the top of your tmux.conf).
        '';
        default = [ ];
        example = literalExample ''
          with pkgs; [
            tmuxPlugins.cpu
            {
              plugin = tmuxPlugins.resurrect;
              extraConfig = "set -g @resurrect-strategy-nvim 'session'";
            }
            {
              plugin = tmuxPlugins.continuum;
              extraConfig = '''
                set -g @continuum-restore 'on'
                set -g @continuum-save-interval '60' # minutes
              ''';
            }
          ];
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration to add.";
        default = "";
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {
        home.packages = [ cfg.package ]
          ++ optional cfg.tmuxinator.enable cfg.tmuxinator.package
          ++ optional cfg.tmuxp.enable      cfg.tmuxp.package;
      }

      (mkIf (cfg.extraConfig != "") {
        home.file.".tmux.conf".text = cfg.extraConfig;
      })

      (mkIf (cfg.sensibleOnTop) {
        home.file.".tmux.conf".text = mkBefore ''
        # ============================================= #
        # Start with defaults from the Sensible plugin  #
        # --------------------------------------------- #
        run-shell ${pkgs.tmuxPlugins.sensible.rtp}
        # ============================================= #
        '';
      })
      (mkIf (cfg.plugins != []) {
        assertions = [
          (let
            not = x: if x then false else true;
            badPlugins = filter (p: not (hasPrefix "tmuxplugin" (pluginName p))) cfg.plugins;
            in
          {
            assertion = badPlugins == [];
            message = "Invalid Tmux plugin (not prefixed with tmuxPlugins): "
                  + concatMapStringsSep ", " pluginName badPlugins;
          })
        ];
        home.file.".tmux.conf".text = mkAfter ''
        # ============================================= #
        # Load plugins with home-manager                #
        # --------------------------------------------- #
        ${(concatMapStringsSep "\n\n" (p: ''
            # ${pluginName p}
            # ---------------------
            ${if hasAttr "extraConfig" p then p.extraConfig else ""}
            run-shell ${if types.package.check p
                then p.rtp
                else p.plugin.rtp}
        '') cfg.plugins)}

        # ============================================= #
        '';
      })
    ]
  );
}
