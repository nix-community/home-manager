{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.starship;

  configFile = config:
    pkgs.runCommand "config.toml" {
      buildInputs = [ pkgs.remarshal ];
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      remarshal -if json -of toml \
        < ${pkgs.writeText "config.json" (builtins.toJSON config)} \
        > $out
    '';

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.starship = {
    enable = mkEnableOption "starship";

    package = mkOption {
      type = types.package;
      default = pkgs.starship;
      defaultText = literalExample "pkgs.starship";
      description = "The package to use for the starship binary.";
    };

    settings = mkOption {
      type = with types;
        let
          prim = either bool (either int str);
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Starship configuration"; };
      default = { };
      example = literalExample ''
        {
          add_newline = false;
          prompt_order = [ "line_break" "package" "line_break" "character" ];
          scan_timeout = 10;
          character.symbol = "➜";
        }
      '';
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
    home.packages = [ cfg.package ];

    xdg.configFile."starship.toml" =
      mkIf (cfg.settings != { }) { source = configFile cfg.settings; };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ $TERM != "dumb" && (-z $INSIDE_EMACS || $INSIDE_EMACS == "vterm") ]]; then
        eval "$(${cfg.package}/bin/starship init bash)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [ -z "$INSIDE_EMACS" ]; then
        eval "$(${cfg.package}/bin/starship init zsh)"
      fi
    '';

    programs.fish.promptInit = mkIf cfg.enableFishIntegration ''
      if test "$TERM" != "dumb"  -a \( -z "$INSIDE_EMACS"  -o "$INSIDE_EMACS" = "vterm" \)
        eval (${cfg.package}/bin/starship init fish)
      end
    '';
  };
}
