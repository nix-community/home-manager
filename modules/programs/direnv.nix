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

  meta.maintainers = with lib.maintainers; [ khaneliman rycee shikanime ];

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

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption {
      inherit config;
      extraDescription = ''
        Note, enabling the direnv module will always activate its functionality
        for Fish since the direnv package automatically gets loaded in Fish.
        If this is not the case try adding

        ```nix
        environment.pathsToLink = [ "/share/fish" ];
        ```

        to the system configuration.
      '';
    } // {
      default = true;
      readOnly = true;
    };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    nix-direnv = {
      enable = mkEnableOption ''
        [nix-direnv](https://github.com/nix-community/nix-direnv),
        a fast, persistent use_nix implementation for direnv'';

      package = mkPackageOption pkgs "nix-direnv" { };
    };

    mise = {
      enable = mkEnableOption ''
        [mise](https://mise.jdx.dev/direnv.html),
        integration of use_mise for direnv'';

      package = mkPackageOption pkgs "mise" { };
    };

    silent = mkEnableOption "silent mode, that is, disabling direnv logging";
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

    xdg.configFile."direnv/lib/hm-mise.sh" = mkIf cfg.mise.enable {
      text = ''
        eval "$(${getExe cfg.mise.package} direnv activate)"
      '';
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        eval "$(${getExe cfg.package} hook bash)"
      '');

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(${getExe cfg.package} hook zsh)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      mkAfter ''
        ${getExe cfg.package} hook fish | source
      '');

    # Using mkAfter to make it more likely to appear after other
    # manipulations of the prompt.
    programs.nushell.extraConfig = mkIf cfg.enableNushellIntegration (mkAfter ''
      $env.config = ($env.config? | default {})
      $env.config.hooks = ($env.config.hooks? | default {})
      $env.config.hooks.pre_prompt = (
          $env.config.hooks.pre_prompt?
          | default []
          | append {||
              ${getExe cfg.package} export json
              | from json --strict
              | default {}
              | items {|key, value|
                  let value = do (
                      $env.ENV_CONVERSIONS?
                      | default {}
                      | get -i $key
                      | get -i from_string
                      | default {|x| $x}
                  ) $value
                  return [ $key $value ]
              }
              | into record
              | load-env
          }
      )
    '');

    home.sessionVariables = lib.mkIf cfg.silent { DIRENV_LOG_FORMAT = ""; };
  };
}
