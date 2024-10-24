{ config, lib, pkgs, ... }:

with lib;

{
  imports = let
    msg = ''
      'programs.eza.enableAliases' has been deprecated and replaced with integration
      options per shell, for example, 'programs.eza.enableBashIntegration'.

      Note, the default for these options is 'true' so if you want to enable the
      aliases you can simply remove 'programs.eza.enableAliases' from your
      configuration.'';
    mkRenamed = opt:
      mkRenamedOptionModule [ "programs" "exa" opt ] [ "programs" "eza" opt ];
  in (map mkRenamed [ "enable" "extraOptions" "icons" "git" ])
  ++ [ (mkRemovedOptionModule [ "programs" "eza" "enableAliases" ] msg) ];

  meta.maintainers = [ maintainers.cafkafk ];

  options.programs.eza = {
    enable = mkEnableOption "eza, a modern replacement for {command}`ls`";

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableIonIntegration = mkEnableOption "Ion integration" // {
      default = true;
    };

    enableNushellIntegration = mkEnableOption "Nushell integration";

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--group-directories-first" "--header" ];
      description = ''
        Extra command line options passed to eza.
      '';
    };

    icons = mkOption {
      type = types.enum [ null true false "auto" "always" "never" ];
      default = null;
      description = ''
        Display icons next to file names ({option}`--icons` argument).

        Note, the support for Boolean values is deprecated.
        Setting this option to `true` corresponds to `--icons=auto`.
      '';
    };

    colors = mkOption {
      type = types.enum [ null "auto" "always" "never" ];
      default = null;
      description = ''
        Use terminal colors in output ({option}`--color` argument).
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

    iconsOption = let
      v = if isBool cfg.icons then
        (if cfg.icons then "auto" else null)
      else
        cfg.icons;
    in optionals (v != null) [ "--icons" v ];

    colorOption = optionals (cfg.colors != null) [ "--color" cfg.colors ];

    args = escapeShellArgs (iconsOption ++ colorOption
      ++ optional cfg.git "--git" ++ cfg.extraOptions);

    optionsAlias = optionalAttrs (args != "") { eza = "eza ${args}"; };

    aliases = builtins.mapAttrs (_name: value: lib.mkDefault value) {
      ls = "eza";
      ll = "eza -l";
      la = "eza -a";
      lt = "eza --tree";
      lla = "eza -la";
    };
  in mkIf cfg.enable {
    warnings = optional (isBool cfg.icons) ''
      Setting programs.eza.icons to a Boolean is deprecated.
      Please update your configuration so that

        programs.eza.icons = ${if cfg.icons then ''"auto"'' else "null"}'';

    home.packages = [ cfg.package ];

    programs.bash.shellAliases = optionsAlias
      // optionalAttrs cfg.enableBashIntegration aliases;

    programs.zsh.shellAliases = optionsAlias
      // optionalAttrs cfg.enableZshIntegration aliases;

    programs.fish = mkMerge [
      (mkIf (!config.programs.fish.preferAbbrs) {
        shellAliases = optionsAlias
          // optionalAttrs cfg.enableFishIntegration aliases;
      })

      (mkIf config.programs.fish.preferAbbrs {
        shellAliases = optionsAlias;
        shellAbbrs = optionalAttrs cfg.enableFishIntegration aliases;
      })
    ];

    programs.ion.shellAliases = optionsAlias
      // optionalAttrs cfg.enableIonIntegration aliases;

    programs.nushell.shellAliases = optionsAlias
      // optionalAttrs cfg.enableNushellIntegration aliases;
  };
}
