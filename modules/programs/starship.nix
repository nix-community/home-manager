{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.starship;

  tomlFormat = pkgs.formats.toml { };

  starshipCmd = "${config.home.profileDirectory}/bin/starship";

  initFish =
    if cfg.enableInteractive then "interactiveShellInit" else "shellInitLast";
in {
  meta.maintainers = [ maintainers.kpbaks ];

  options.programs.starship = {
    enable = mkEnableOption "starship";

    package = mkOption {
      type = types.package;
      default = pkgs.starship;
      defaultText = literalExpression "pkgs.starship";
      description = "The package to use for the starship binary.";
    };

    preset = mkOption {
      # generated with `starship preset --list`
      type = types.enum [
        null
        "bracketed-segments"
        "gruvbox-rainbow"
        "jetpack"
        "nerd-font-symbols"
        "no-empty-icons"
        "no-nerd-font"
        "no-runtime-versions"
        "pastel-powerline"
        "plain-text-symbols"
        "pure-preset"
        "tokyo-night"
      ];
      default = null;
      example = "jetpack";
      description = ''
        The community-submitted configuration preset to use.

        See <https://starship.rs/presets/#presets> for previews
        of each preset.

        Mutually exclusive with programs.starship.settings
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
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

    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };

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

    warnings = lib.optional (cfg.preset != null && cfg.settings != { })
      "programs.starship.settings has no effect when programs.starship.preset != null";

    xdg.configFile."starship.toml" = if cfg.preset != null then
      let
        starshipGithub = pkgs.fetchFromGitHub {
          owner = "starship";
          repo = "starship";
          rev = "61c860e1293d446d515203ac44055f7bef77d14a";
          hash = "sha256-pl3aW4zCM6CcYOL0dUwE56aTC7BJdvdRyo/GudvX7fQ=";
        };
      in {
        text = builtins.readFile
          "${starshipGithub}/docs/public/presets/toml/${cfg.preset}.toml";
      }
    else if cfg.settings != { } then {
      source = tomlFormat.generate "starship-config" cfg.settings;
    } else
      { };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${starshipCmd} init bash --print-full-init)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $TERM != "dumb" ]]; then
        eval "$(${starshipCmd} init zsh)"
      fi
    '';

    programs.fish.${initFish} = mkIf cfg.enableFishIntegration ''
      if test "$TERM" != "dumb"
        ${starshipCmd} init fish | source
        ${lib.optionalString cfg.enableTransience "enable_transience"}
      end
    '';

    programs.ion.initExtra = mkIf cfg.enableIonIntegration ''
      if test $TERM != "dumb"
        eval $(${starshipCmd} init ion)
      end
    '';

    programs.nushell = mkIf cfg.enableNushellIntegration {
      # Unfortunately nushell doesn't allow conditionally sourcing nor
      # conditionally setting (global) environment variables, which is why the
      # check for terminal compatibility (as seen above for the other shells) is
      # not done here.
      extraEnv = ''
        let starship_cache = "${config.xdg.cacheHome}/starship"
        if not ($starship_cache | path exists) {
          mkdir $starship_cache
        }
        ${starshipCmd} init nu | save --force ${config.xdg.cacheHome}/starship/init.nu
      '';
      extraConfig = ''
        use ${config.xdg.cacheHome}/starship/init.nu
      '';
    };
  };
}
