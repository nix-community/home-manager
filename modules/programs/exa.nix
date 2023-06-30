{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ hm.maintainers.kalhauge ];

  options.programs.exa = {
    enable =
      mkEnableOption (lib.mdDoc "exa, a modern replacement for {command}`ls`");

    enableAliases =
      mkEnableOption (lib.mdDoc "recommended exa aliases (ls, ll…)");

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--group-directories-first" "--header" ];
      description = lib.mdDoc ''
        Extra command line options passed to exa.
      '';
    };

    icons = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Display icons next to file names ({option}`--icons` argument).
      '';
    };

    git = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        List each file's Git status if tracked or ignored ({option}`--git` argument).
      '';
    };

    package = mkPackageOptionMD pkgs "exa" { };
  };

  config = let
    cfg = config.programs.exa;

    args = escapeShellArgs (optional cfg.icons "--icons"
      ++ optional cfg.git "--git" ++ cfg.extraOptions);

    aliases = {
      exa = "exa ${args}";
    } // optionalAttrs cfg.enableAliases {
      ls = "exa";
      ll = "exa -l";
      la = "exa -a";
      lt = "exa --tree";
      lla = "exa -la";
    };
  in mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.shellAliases = aliases;

    programs.zsh.shellAliases = aliases;

    programs.fish.shellAliases = aliases;

    programs.ion.shellAliases = aliases;
  };
}
