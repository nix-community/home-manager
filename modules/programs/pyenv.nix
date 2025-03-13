{ config, pkgs, lib, ... }:

let

  cfg = config.programs.pyenv;

  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = with lib.maintainers; [ tmarkus ];

  options.programs.pyenv = {
    enable = lib.mkEnableOption "pyenv";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pyenv;
      defaultText = lib.literalExpression "pkgs.pyenv";
      description = "The package to use for pyenv.";
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

    rootDirectory = lib.mkOption {
      type = lib.types.path;
      apply = toString;
      default = "${config.xdg.dataHome}/pyenv";
      defaultText = "\${config.xdg.dataHome}/pyenv";
      description = ''
        The pyenv root directory ({env}`PYENV_ROOT`).

        ::: {.note}
        This deviates from upstream, which uses {file}`$HOME/.pyenv`.
        The default path in Home Manager is set according to the XDG
        base directory specification.
        :::
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Always add the configured `pyenv` package.
    home.packages = [ cfg.package ];

    programs.bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
      export PYENV_ROOT="${cfg.rootDirectory}"
      eval "$(${lib.getExe cfg.package} init - bash)"
    '';

    programs.zsh.initExtra = lib.mkIf cfg.enableZshIntegration ''
      export PYENV_ROOT="${cfg.rootDirectory}"
      eval "$(${lib.getExe cfg.package} init - zsh)"
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      set -Ux PYENV_ROOT "${cfg.rootDirectory}"
      ${lib.getExe cfg.package} init - fish | source
    '';
  };
}
