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
    (mkRemovedOptionModule [ "programs" "direnv" "nix-direnv" "enableFlakes" ]
      "Flake support is now always enabled.")
  ];

  meta.maintainers = [ maintainers.rycee ];

  options.programs.direnv = {
    enable = mkEnableOption "direnv, the environment switcher";

    config = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/direnv/direnv.toml</filename>.
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
        <filename>$XDG_CONFIG_HOME/direnv/direnvrc</filename>.
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
        automatically gets loaded in Fish. If this is not the case try adding
        <programlisting language="nix">
          environment.pathsToLink = [ "/share/fish" ];
        </programlisting>
        to the system configuration.
      '';
    };

    enableNushellIntegration = mkOption {
      default = true;
      type = types.bool;
      readOnly = true;
      description = ''
        Whether to enable Nushell integration.
      '';
    };

    nix-direnv = {
      enable = mkEnableOption ''
        <link
            xlink:href="https://github.com/nix-community/nix-direnv">nix-direnv</link>,
            a fast, persistent use_nix implementation for direnv'';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.direnv ];

    xdg.configFile."direnv/direnv.toml" = mkIf (cfg.config != { }) {
      source = tomlFormat.generate "direnv-config" cfg.config;
    };

    xdg.configFile."direnv/direnvrc" = let
      text = concatStringsSep "\n" (optional (cfg.stdlib != "") cfg.stdlib
        ++ optional cfg.nix-direnv.enable
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

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        ${pkgs.direnv}/bin/direnv hook fish | source
      '');

    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        let-env config = ($env | default {} config).config
        let-env config = ($env.config | default {} hooks)
        let-env config = ($env.config | update hooks ($env.config.hooks | default [] pre_prompt))
        let-env config = ($env.config | update hooks.pre_prompt ($env.config.hooks.pre_prompt | append {
          code: "
            let direnv = (${pkgs.direnv}/bin/direnv export json | from json)
            let direnv = if ($direnv | length) == 1 { $direnv } else { {} }
            $direnv | load-env
            "
        }))
      '');
  };
}
