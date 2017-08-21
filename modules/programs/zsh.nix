{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

in

{
  options = {
    programs.zsh = {
      enable = mkEnableOption "Z shell (Zsh)";

      historySize = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of history lines to keep.";
      };

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
        description = ''
          Enable zsh completion.
        '';
        type = types.bool;
      };

      enableAutosuggestions = mkOption {
        default = false;
        description = ''
          Enable zsh autosuggestions
        '';
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
      exportIfNonNull = n: v: optionalString (v != null) (export n v);
      exportIfNonEmpty = n: v: optionalString (v != "") (export n v);

      histControlStr = concatStringsSep ":" cfg.historyControl;
      histIgnoreStr = concatStringsSep ":" cfg.historyIgnore;

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
        ${export "HISTSIZE" cfg.historySize}

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
