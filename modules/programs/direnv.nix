{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.direnv;
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
  meta.maintainers = [ maintainers.rycee ];

  options.programs.direnv = {
    enable = mkEnableOption "direnv, the environment switcher";

    config = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Configuration written to
        <filename>~/.config/direnv/config.toml</filename>.
        </para><para>
        See
        <citerefentry>
          <refentrytitle>direnv.toml</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>.
        for the full list of options.
      '';
    };

    stdlib = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Custom stdlib written to
        <filename>~/.config/direnv/direnvrc</filename>.
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

    enableNixDirenvIntegration = mkEnableOption ''
      <link
          xlink:href="https://github.com/nix-community/nix-direnv">nix-direnv</link>,
          a fast, persistent use_nix implementation for direnv'';
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.direnv ];

    xdg.configFile."direnv/config.toml" =
      mkIf (cfg.config != { }) { source = configFile cfg.config; };

    xdg.configFile."direnv/direnvrc" = let
      text = concatStringsSep "\n" (optional (cfg.stdlib != "") cfg.stdlib
        ++ optional cfg.enableNixDirenvIntegration
        "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc");
    in mkIf (text != "") { inherit text; };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        eval "$(${pkgs.direnv}/bin/direnv hook bash)"
      '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
    '';

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      eval (${pkgs.direnv}/bin/direnv hook fish)
    '';
  };
}
