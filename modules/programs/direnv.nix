{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.direnv;

  tomlFormat = pkgs.formats.toml { };

in {
  imports = [
    (mkRenamedOptionModule [
      "programs"
      "direnv"
      "enableNixDirenvIntegration"
    ] [ "programs" "direnv" "nix-direnv" "enable" ])
  ];

  meta.maintainers = [ maintainers.rycee ];

  options.programs.direnv = {
    enable = mkEnableOption "direnv, the environment switcher";

    config = mkOption {
      type = tomlFormat.type;
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
      readOnly = true;
      description = ''
        Whether to enable Fish integration. Note, enabling the direnv module
        will always active its functionality for Fish since the direnv package
        automatically gets loaded in Fish.
      '';
    };

    nix-direnv = {
      enable = mkEnableOption ''
        <link
            xlink:href="https://github.com/nix-community/nix-direnv">nix-direnv</link>,
            a fast, persistent use_nix implementation for direnv'';
      enableFlakes = mkEnableOption "Flake support in nix-direnv";
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.direnv ];

    xdg.configFile."direnv/config.toml" = mkIf (cfg.config != { }) {
      source = tomlFormat.generate "direnv-config" cfg.config;
    };

    xdg.configFile."direnv/direnvrc" = let
      package =
        pkgs.nix-direnv.override { inherit (cfg.nix-direnv) enableFlakes; };
      text = concatStringsSep "\n" (optional (cfg.stdlib != "") cfg.stdlib
        ++ optional cfg.nix-direnv.enable
        "source ${package}/share/nix-direnv/direnvrc");
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
  };
}
