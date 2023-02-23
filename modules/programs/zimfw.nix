{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

  ## copied relToDotDir from ./zsh.nix. Probably should import it, but I don't
  ## know how.
  relToDotDir = file:
    (optionalString (cfg.dotDir != null) (cfg.dotDir + "/")) + file;

in {
  meta.maintainers = [ maintainers.joedevivo ];

  options = {
    programs.zsh.zimfw = {
      enable = mkEnableOption "Zim - ${pkgs.zimfw.meta.description}";

      homeDir = mkOption {
        default = "$HOME/.zim";
        example = "$HOME/.cache/zim";
        type = types.str;
        description = ''
          Working directory for zim. It stores downloaded plugins here.
        '';
      };

      configFile = mkOption {
        default = if cfg.dotDir != null then
          "$HOME/${cfg.dotDir}/.zimrc"
        else
          "$HOME/.zimrc";
        type = types.str;
        description = ''
          Location of zimrc file
        '';
      };

      degit = mkOption {
        default = true;
        example = false;
        type = types.bool;
        description = ''
          Use zim's degit tool for faster module installation.
        '';
      };

      disableVersionCheck = mkOption {
        default = false;
        type = types.bool;
        description = ''
          disables 30 day version check
        '';
      };

      zmodules = mkOption {
        default = [ "environment" "git" "input" "termtitle" "utility" ];
        example = [
          "environment"
          "git"
          "input"
          "termtitle"
          "utility"
          "exa"
          "$PATH_TO_LOCAL_MODULE"
          "duration-info"
          "git-info"
        ];
        type = types.listOf types.str;
        description = ''
          List of zimfw modules. These are added to `.zimrc` verbatim,
          so ENV vars will work for paths to local modules.
        '';
      };
    };
  };

  config = mkIf cfg.zimfw.enable {
    home.packages = [ pkgs.zimfw ];
    programs.zsh.localVariables = {
      ZIM_HOME = cfg.zimfw.homeDir;
      ZIM_CONFIG_FILE = cfg.zimfw.configFile;
    };
    programs.zsh.initExtra = concatStringsSep "\n" ([
      (optionalString (cfg.zimfw.degit) ''
        zstyle ':zim:zmodule' use 'degit'
      '')
      (optionalString (cfg.zimfw.disableVersionCheck) ''
        zstyle ':zim' disable-version-check yes
      '')
      ''
        # Ensure zimfw is installed before attempting to load.
        if [[ -e ${pkgs.zimfw}/zimfw.zsh ]]; then
          if [[ ! -e ''${ZIM_HOME} ]]; then
            mkdir -p ''${ZIM_HOME}
          fi
          # Install missing modules, and update ''${ZIM_HOME}/init.zsh
          # if missing or outdated.
          if [[ ! ''${ZIM_HOME}/init.zsh -nt ''${ZIM_CONFIG_FILE} ]]; then
            source ${pkgs.zimfw}/zimfw.zsh init -q
          fi
          source ''${ZIM_HOME}/init.zsh
        fi
      ''
    ]);
    home.file."${relToDotDir ".zimrc"}".text = concatStringsSep "\n"
      ((map (zmodule: "zmodule ${zmodule}") cfg.zimfw.zmodules));
    home.activation.zimfw = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      zsh -c "export ZIM_HOME='${cfg.zimfw.homeDir}' && source ${pkgs.zimfw}/zimfw.zsh init -q && zimfw install && zimfw compile"
    '';
  };
}
