{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkOption mkRenamedOptionModule mkRemovedOptionModule mkEnableOption types
    mkPackageOption mkIf mkAfter getExe;

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

  meta.maintainers = [ lib.maintainers.rycee ];

  options.programs.direnv = {
    enable = mkEnableOption "direnv, the environment switcher";

    package = mkPackageOption pkgs "direnv" { };

    config = mkOption {
      type = tomlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/direnv/direnv.toml`.

        See
        {manpage}`direnv.toml(1)`.
        for the full list of options.
      '';
    };

    stdlib = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Custom stdlib written to
        {file}`$XDG_CONFIG_HOME/direnv/direnvrc`.
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
        ```nix
          environment.pathsToLink = [ "/share/fish" ];
        ```
        to the system configuration.
      '';
    };

    enableNushellIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Nushell integration.
      '';
    };

    nix-direnv = {
      enable = mkEnableOption ''
        [nix-direnv](https://github.com/nix-community/nix-direnv),
        a fast, persistent use_nix implementation for direnv'';

      package = mkPackageOption pkgs "nix-direnv" { };
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."direnv/direnv.toml" = mkIf (cfg.config != { }) {
      source = tomlFormat.generate "direnv-config" cfg.config;
    };

    xdg.configFile."direnv/lib/hm-nix-direnv.sh" = mkIf cfg.nix-direnv.enable {
      source = "${cfg.nix-direnv.package}/share/nix-direnv/direnvrc";
    };

    xdg.configFile."direnv/direnvrc" =
      lib.mkIf (cfg.stdlib != "") { text = cfg.stdlib; };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        eval "$(${getExe cfg.package} hook bash)"
      '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${getExe cfg.package} hook zsh)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        ${getExe cfg.package} hook fish | source
      '');

    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        $env.config = ($env.config? | default {})
        $env.config.hooks = ($env.config.hooks? | default {})
        $env.config.hooks.pre_prompt = (
            $env.config.hooks.pre_prompt?
            | default []
            | append {||
                let direnv = (${getExe cfg.package} export json
                | from json
                | default {})
                if ($direnv | is-empty) {
                    return
                }
                $direnv
                | items {|key, value|
                    {
                        key: $key
                        value: (do (
                            $env.ENV_CONVERSIONS?
                            | default {}
                            | get -i $key
                            | get -i from_string
                            | default {|x| $x}
                        ) $value)
                    }
                }
                | transpose -ird
                | load-env
            }
        )
      '');
  };
}
