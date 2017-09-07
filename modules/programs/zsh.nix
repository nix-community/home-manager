{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

  historyModule = types.submodule {
    options = {
      size = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of history lines to keep.";
      };

      path = mkOption {
        type = types.str;
        default = "$HOME/.zsh_history";
        description = "History file location";
      };

      ignoreDups = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Do not enter command lines into the history list
          if they are duplicates of the previous event.
        '';
      };

      share = mkOption {
        type = types.bool;
        default = true;
        description = "Share command history between zsh sessions.";
      };
    };
  };

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.

          Will be added to <envar>fpath</envar> and <envar>PATH</envar>.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.

          Don't forget to add <option>file</option>
          if the script name does not follow convention.
        '';
      };

      file = mkOption {
        type = types.str;
        description = "The plugin script to source.";
      };
    };

    config.file = mkDefault "${config.name}.plugin.zsh";
  });

  ohMyZshModule = types.submodule {
    options = {
      enable = mkEnableOption "oh-my-zsh";

      plugins = mkOption {
        default = [];
        example = [ "git" "sudo" ];
        type = types.listOf types.str;
        description = ''
          List of oh-my-zsh plugins
        '';
      };

      custom = mkOption {
        default = "";
        type = types.str;
        example = "$HOME/my_customizations";
        description = ''
          Path to a custom oh-my-zsh package to override config of oh-my-zsh.
          See: https://github.com/robbyrussell/oh-my-zsh/wiki/Customization
        '';
      };

      theme = mkOption {
        default = "";
        example = "robbyrussell";
        type = types.str;
        description = ''
          Name of the theme to be used by oh-my-zsh.
        '';
      };
    };
  };

in

{
  options = {
    programs.zsh = {
      enable = mkEnableOption "Z shell (Zsh)";

      shellAliases = mkOption {
        default = {};
        example = { ll = "ls -l"; ".." = "cd .."; };
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
        type = types.attrs;
      };

      enableCompletion = mkOption {
        default = true;
        description = "Enable zsh completion.";
        type = types.bool;
      };

      enableAutosuggestions = mkOption {
        default = false;
        description = "Enable zsh autosuggestions";
      };

      history = mkOption {
        type = historyModule;
        default = {};
        description = "Options related to commands history configuration.";
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zshrc</filename>.";
      };

      plugins = mkOption {
        type = types.listOf pluginModule;
        default = [];
        example = literalExample ''
          [
            {
              # will source zsh-autosuggestions.plugin.zsh
              name = "zsh-autosuggestions";
              src = pkgs.fetchFromGitHub {
                owner = "zsh-users";
                repo = "zsh-autosuggestions";
                rev = "v0.4.0";
                sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
              };
            }
            {
              name = "enhancd";
              file = "init.sh";
              src = pkgs.fetchFromGitHub {
                owner = "b4b4r07";
                repo = "enhancd";
                rev = "v2.2.1";
                sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
              };
            }
          ]
        '';
        description = "Plugins to source in <filename>.zshrc</filename>.";
      };

      oh-my-zsh = mkOption {
        type = ohMyZshModule;
        default = {};
        description = "Options to configure oh-my-zsh.";
      };
    };
  };

  config = mkMerge [
    (let
      aliasesStr = concatStringsSep "\n" (
        mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
      );

      export = n: v: "export ${n}=\"${toString v}\"";

      envVarsStr = concatStringsSep "\n" (
        mapAttrsToList export config.home.sessionVariables
      );
    in mkIf cfg.enable {
      home.packages = with pkgs; [ zsh ]
        ++ optional cfg.enableCompletion nix-zsh-completions
        ++ optional cfg.oh-my-zsh.enable oh-my-zsh;

      home.file.".zshenv".text = ''
        ${optionalString (config.home.sessionVariableSetter == "zsh")
          envVarsStr}
      '';

      home.file.".zshrc".text = ''
        ${export "HISTSIZE" cfg.history.size}
        ${export "HISTFILE" cfg.history.path}

        setopt HIST_FCNTL_LOCK
        ${if cfg.history.ignoreDups then "setopt" else "unsetopt"} HIST_IGNORE_DUPS
        ${if cfg.history.share then "setopt" else "unsetopt"} SHARE_HISTORY

        HELPDIR="${pkgs.zsh}/share/zsh/$ZSH_VERSION/help"

        ${concatStrings (map (plugin: ''
          path+="$HOME/.zsh/plugins/${plugin.name}"
          fpath+="$HOME/.zsh/plugins/${plugin.name}"
        '') cfg.plugins)}

        ${optionalString cfg.enableCompletion "autoload -U compinit && compinit"}
        ${optionalString (cfg.enableAutosuggestions)
          "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        }

        ${optionalString cfg.oh-my-zsh.enable ''
            # oh-my-zsh configuration generated by NixOS
            export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
            export ZSH_CACHE_DIR=''${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh

            ${optionalString (cfg.oh-my-zsh.plugins != [])
              "plugins=(${concatStringsSep " " cfg.oh-my-zsh.plugins})"
            }
            ${optionalString (cfg.oh-my-zsh.custom != "")
              "ZSH_CUSTOM=\"${cfg.oh-my-zsh.custom}\""
            }
            ${optionalString (cfg.oh-my-zsh.theme != "")
              "ZSH_THEME=\"${cfg.oh-my-zsh.theme}\""
            }
            source $ZSH/oh-my-zsh.sh
        ''}

        ${concatStrings (map (plugin: ''
          source "$HOME/.zsh/plugins/${plugin.name}/${plugin.file}"
        '') cfg.plugins)}

        ${cfg.initExtra}

        ${aliasesStr}
      '';
    })
    (mkIf cfg.oh-my-zsh.enable {
      # Oh-My-Zsh calls compinit during initialization,
      # calling it twice causes sight start up slowdown
      # as all $fpath entries will be traversed again.
      programs.zsh.enableCompletion = mkForce false;
    })
    (mkIf (cfg.plugins != []) {
      # Many plugins require compinit to be called
      # but allow the user to opt out.
      programs.zsh.enableCompletion = mkDefault true;

      home.file = map (plugin: {
        target = ".zsh/plugins/${plugin.name}";
        source = plugin.src;
      }) cfg.plugins;
    })
  ];
}
