{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.tmux;

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
      enable = mkEnableOption "tmux";

      package = mkOption {
        type = types.package;
        default = pkgs.tmux;
        defaultText = "pkgs.tmux";
        example = literalExample "pkgs.tmux";
        description = "The tmux package to install";
      };

      sensibleOnTop = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Run the sensible plugin at the top of the configuration. It
          is possible to override the sensible settings using the
          <option>programs.tmux.extraConfig</option> option.
        '';
      };

      tmuxp.enable = mkEnableOption "tmuxp";

      tmuxinator.enable = mkEnableOption "tmuxinator";

      plugins = mkOption {
        type = with types;
          listOf (either package pluginModule)
          // { description = "list of plugin packages or submodules"; };
        description = ''
          List of tmux plugins to be included at the end of your tmux
          configuration. The sensible plugin, however, is defaulted to
          run at the top of your configuration.
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
          ]
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional configuration to add to
          <filename>tmux.conf</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    mkMerge [
      {
        home.packages = [ cfg.package ]
          ++ optional cfg.tmuxinator.enable pkgs.tmuxinator
          ++ optional cfg.tmuxp.enable      pkgs.tmuxp;

          home.file.".tmux.conf".text = cfg.extraConfig;
      }

      (mkIf cfg.sensibleOnTop {
        home.file.".tmux.conf".text = mkBefore ''
          # ============================================= #
          # Start with defaults from the Sensible plugin  #
          # --------------------------------------------- #
          run-shell ${pkgs.tmuxPlugins.sensible.rtp}
          # ============================================= #
        '';
      })

      (mkIf (cfg.plugins != []) {
        assertions = [(
          let
            hasBadPluginName = p: !(hasPrefix "tmuxplugin" (pluginName p));
            badPlugins = filter hasBadPluginName cfg.plugins;
          in
            {
              assertion = badPlugins == [];
              message =
                "Invalid tmux plugin (not prefixed with \"tmuxplugins\"): "
                + concatMapStringsSep ", " pluginName badPlugins;
            }
        )];

        home.file.".tmux.conf".text = mkAfter ''
          # ============================================= #
          # Load plugins with Home Manager                #
          # --------------------------------------------- #

          ${(concatMapStringsSep "\n\n" (p: ''
              # ${pluginName p}
              # ---------------------
              ${p.extraConfig or ""}
              run-shell ${
                if types.package.check p
                then p.rtp
                else p.plugin.rtp
              }
          '') cfg.plugins)}
          # ============================================= #
        '';
      })
    ]
  );
}
