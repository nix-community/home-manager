{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.starship;

  tomlFormat = pkgs.formats.toml { };

  initFish = if cfg.enableInteractive then "interactiveShellInit" else "shellInitLast";
in
{
  meta.maintainers = [ lib.maintainers.kpbaks ];

  options.programs.starship = {
    enable = lib.mkEnableOption "starship";

    package = lib.mkPackageOption pkgs "starship" { };

    preset = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "jetpack";
      description = ''
        The community-submitted configuration preset to use.

        See <https://starship.rs/presets/#presets> for previews
        of each preset, and use `starship preset --list` to quickly
        list the names of each of them.

        Mutually exclusive with programs.starship.settings
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          add_newline = false;
          format = lib.concatStrings [
            "$line_break"
            "$package"
            "$line_break"
            "$character"
          ];
          scan_timeout = 10;
          character = {
            success_symbol = "➜";
            error_symbol = "➜";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/starship.toml`.

        See <https://starship.rs/config/> for the full list
        of options.

        Mutually exclusive with programs.starship.preset
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableIonIntegration = lib.hm.shell.mkIonIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableInteractive = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Only enable starship when the shell is interactive. This option is only
        valid for the Fish shell.

        Some plugins require this to be set to `false` to function correctly.
      '';
    };

    enableTransience = mkOption {
      type = types.bool;
      default = false;
      description = ''
        The TransientPrompt feature of Starship replaces previous prompts with a
        custom string. This is only a valid option for the Fish shell.

        For documentation on how to change the default replacement string and
        for more information visit
        https://starship.rs/advanced-config/#transientprompt-and-transientrightprompt-in-cmd
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    warnings = lib.optional (
      cfg.preset != null && cfg.settings != { }
    ) "programs.starship.settings has no effect when programs.starship.preset != null";

    xdg.configFile."starship.toml" =
      if cfg.preset != null then
        let
          starshipGithub = pkgs.fetchFromGitHub {
            owner = "starship";
            repo = "starship";
            tag = "v1.23.0";
            hash = "sha256-fJbqKBRRLFNguRtHqwhPLNPmhJvXqcfdQi+vQIGmrBw=";
          };
        in
        {
          source = "${starshipGithub}/docs/public/presets/toml/${cfg.preset}.toml";
        }
      else if cfg.settings != { } then
        {
          source = tomlFormat.generate "starship-config" cfg.settings;
        }
      else
        { };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${lib.getExe cfg.package} init bash --print-full-init)"
      fi
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${lib.getExe cfg.package} init zsh)"
      fi
    '';

    programs.fish.${initFish} = mkIf cfg.enableFishIntegration ''
      if test "$TERM" != "dumb"
        ${lib.getExe cfg.package} init fish | source
        ${lib.optionalString cfg.enableTransience "enable_transience"}
      end
    '';

    programs.ion.initExtra = mkIf cfg.enableIonIntegration ''
      if test $TERM != "dumb"
        eval $(${lib.getExe cfg.package} init ion)
      end
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      # Unfortunately nushell doesn't allow conditionally sourcing nor
      # conditionally setting (global) environment variables, which is why the
      # check for terminal compatibility (as seen above for the other shells) is
      # not done here.
      extraConfig = ''
        use ${
          pkgs.runCommand "starship-nushell-config.nu" { } ''
            ${lib.getExe cfg.package} init nu >> "$out"
          ''
        }
      '';
    };
  };
}
