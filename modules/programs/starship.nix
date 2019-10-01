{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.starship;

  configFile = config:
    pkgs.runCommand "config.toml"
      {
        buildInputs = [ pkgs.remarshal ];
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      ''
        remarshal -if json -of toml \
          < ${pkgs.writeText "config.json" (builtins.toJSON config)} \
          > $out
      '';
in

{
  meta.maintainers = [ maintainers.marsam ];

  options.programs.starship = {
    enable = mkEnableOption "starship";

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = ''
        Configuration written to
        <filename>~/.config/starship.toml</filename>.
        </para><para>
        See <link xlink:href="https://starship.rs/config/" /> for the full list
        of options.
      '';
    };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.starship ];

    xdg.configFile."starship.toml" = mkIf (cfg.settings != {}) {
      source = configFile cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ -z $INSIDE_EMACS ]]; then
        eval "$(${pkgs.starship}/bin/starship init bash)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [ -z "$INSIDE_EMACS" ]; then
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      fi
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      if test -z "$INSIDE_EMACS"
        eval (${pkgs.starship}/bin/starship init fish)
      end
    '';
  };
}
