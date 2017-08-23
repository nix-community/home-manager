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
        description = "Extra commands that should be added to .zshrc.";
      };
    };
  };

  config = (
    let
      aliasesStr = concatStringsSep "\n" (
        mapAttrsToList (k: v: "alias ${k}='${v}'") cfg.shellAliases
      );

      export = n: v: "export ${n}=\"${toString v}\"";

      envVarsStr = concatStringsSep "\n" (
        mapAttrsToList export config.home.sessionVariables
      );
    in mkIf cfg.enable {
      home.packages = [ pkgs.zsh ]
        ++ optional cfg.enableCompletion pkgs.nix-zsh-completions;

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

        # Tell zsh how to find installed completions
        for p in ''${(z)NIX_PROFILES}; do
          fpath+=($p/share/zsh/site-functions $p/share/zsh/$ZSH_VERSION/functions)
        done

        ${if cfg.enableCompletion then "autoload -U compinit && compinit" else ""}
        ${optionalString (cfg.enableAutosuggestions)
          "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        }

        ${aliasesStr}

        ${cfg.initExtra}
      '';
    }
  );
}
