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

    disabled = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "A list of prompt segments to disable";
      example = [ "battery" ];
    };

    symbols = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "A set of symbols to be displayed with prompt segments";
      example = {
        aws = " ";
        conda = " ";
        git_branch = " ";
        golang = " ";
        package = " ";
        python = " ";
      };
    };

    styles = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "A set of styles to be applies to prompt segments";
      example = { directory = "blue"; };
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
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
    xdg.configFile."starship.toml" = let
      fromKey = key:
        mapAttrs' (name: value: nameValuePair name { "${key}" = value; });
      settings = cfg.settings // (fromKey "symbol" cfg.symbols)
        // (fromKey "style" cfg.styles) // (listToAttrs
          (builtins.map (name: nameValuePair name { disabled = true; })
            cfg.disabled));
    in mkIf (settings != { }) { source = configFile settings; };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ -z $INSIDE_EMACS ]]; then
        eval "$(${cfg.package}/bin/starship init bash)"
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [ -z "$INSIDE_EMACS" ]; then
        eval "$(${cfg.package}/bin/starship init zsh)"
      fi
    '';

    programs.fish.promptInit = mkIf cfg.enableFishIntegration ''
      if test -z "$INSIDE_EMACS"
        eval (${cfg.package}/bin/starship init fish)
      end
    '';
  };
}
