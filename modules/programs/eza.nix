{ config, lib, pkgs, ... }:

with lib;

{
  imports = let
    mkRenamed = opt:
      mkRenamedOptionModule [ "programs" "exa" opt ] [ "programs" "eza" opt ];
  in map mkRenamed [ "enable" "enableAliases" "extraOptions" "icons" "git" ];

  meta.maintainers = [ maintainers.cafkafk ];

  options.programs.eza = {
    enable = mkEnableOption "eza, a modern replacement for {command}`ls`";

    enableAliases = mkEnableOption "recommended eza aliases (ls, ll…)";

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--group-directories-first" "--header" ];
      description = ''
        Extra command line options passed to eza.
      '';
    };

    icons = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Display icons next to file names ({option}`--icons` argument).
      '';
    };

    git = mkOption {
      type = types.bool;
      default = false;
      description = ''
        List each file's Git status if tracked or ignored ({option}`--git` argument).
      '';
    };

    package = mkPackageOption pkgs "eza" { };
  };

  config = let
    cfg = config.programs.eza;

    args = escapeShellArgs (optional cfg.icons "--icons"
      ++ optional cfg.git "--git" ++ cfg.extraOptions);

    aliases = {
      eza = "eza ${args}";
    } // optionalAttrs cfg.enableAliases {
      ls = "eza";
      ll = "eza -l";
      la = "eza -a";
      lt = "eza --tree";
      lla = "eza -la";
    };
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.shellAliases = aliases;

    programs.zsh.shellAliases = aliases;

    programs.fish.shellAliases = aliases;

    programs.ion.shellAliases = aliases;

    programs.nushell.shellAliases = aliases;
  };
}
