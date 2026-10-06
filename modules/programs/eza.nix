{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption optionalAttrs types;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.cafkafk ];

  imports =
    let
      msg = ''
        'programs.eza.enableAliases' has been deprecated and replaced with integration
        options per shell, for example, 'programs.eza.enableBashIntegration'.

        Note, the default for these options is 'true' so if you want to enable the
        aliases you can simply remove 'programs.eza.enableAliases' from your
        configuration.'';
    in
    (lib.mapAttrsToList (name: message: lib.mkRemovedOptionModule [ "programs" "exa" name ] message) {
      enable = "Use `programs.eza.enable` instead.";
      extraOptions = "Use `programs.eza.extraOptions` instead.";
      git = "Use `programs.eza.git` instead.";
      icons = "Use `programs.eza.icons` instead.";
    })
    ++ [ (lib.mkRemovedOptionModule [ "programs" "eza" "enableAliases" ] msg) ];
  options.programs.eza = {
    enable = lib.mkEnableOption "eza, a modern replacement for {command}`ls`";

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableIonIntegration = lib.hm.shell.mkIonIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; } // {
      default = false;
      example = true;
    };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--group-directories-first"
        "--header"
      ];
      description = ''
        Extra command line options passed to eza.
      '';
    };

    icons = mkOption {
      type = types.enum [
        null
        "auto"
        "always"
        "never"
      ];
      default = null;
      description = ''
        Display icons next to file names ({option}`--icons` argument).
      '';
    };

    colors = mkOption {
      type = types.enum [
        null
        "auto"
        "always"
        "never"
      ];
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

    package = lib.mkPackageOption pkgs "eza" { nullable = true; };

    theme = mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = ''
        Written to {file}`$XDG_CONFIG_HOME/eza/theme.yml`

        See <https://github.com/eza-community/eza#custom-themes>
      '';
    };
  };

  config =
    let
      cfg = config.programs.eza;

      iconsOption = lib.optionals (cfg.icons != null) [
        "--icons"
        cfg.icons
      ];

      args = lib.escapeShellArgs (
        iconsOption
        ++ lib.optionals (cfg.colors != null) [
          "--color"
          cfg.colors
        ]
        ++ lib.optional cfg.git "--git"
        ++ cfg.extraOptions
      );

      optionsAlias = optionalAttrs (args != "") { eza = "eza ${args}"; };

      aliases = builtins.mapAttrs (_name: value: lib.mkDefault value) {
        ls = "eza";
        ll = "eza -l";
        la = "eza -a";
        lt = "eza --tree";
        lla = "eza -la";
      };
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile."eza/theme.yml" = lib.mkIf (cfg.theme != { }) {
        source = yamlFormat.generate "eza-theme" cfg.theme;
      };

      programs.bash.shellAliases = optionsAlias // optionalAttrs cfg.enableBashIntegration aliases;

      programs.zsh.shellAliases = optionsAlias // optionalAttrs cfg.enableZshIntegration aliases;

      programs.fish = lib.mkMerge [
        (lib.mkIf (!config.programs.fish.preferAbbrs) {
          shellAliases = optionsAlias // optionalAttrs cfg.enableFishIntegration aliases;
        })

        (lib.mkIf config.programs.fish.preferAbbrs {
          shellAliases = optionsAlias;
          shellAbbrs = optionalAttrs cfg.enableFishIntegration aliases;
        })
      ];

      programs.ion.shellAliases = optionsAlias // optionalAttrs cfg.enableIonIntegration aliases;

      programs.nushell.shellAliases = optionsAlias // optionalAttrs cfg.enableNushellIntegration aliases;
    };
}
