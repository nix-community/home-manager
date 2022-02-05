{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.buf;
in {
  meta.maintainers = [ maintainers.lucperkins ];

  options.programs.buf = {
    enable = mkEnableOption "Buf: a CLI tool for working with Protocol Buffers";

    package = mkOption {
      type = types.package;
      default = pkgs.buf;
      defaultText = literalExpression "pkgs.buf";
      description = "Package providing <command>buf</command>.";
    };

    enableBashIntegration = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to load Bash autocomplete scripts for <command>buf</command>.
      '';
    };

    enableFishIntegration = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to load Fish autocomplete scripts for <command>buf</command>.
      '';
    };

    enableZshIntegration = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to load zsh autocomplete scripts for <command>buf</command>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(${pkgs.buf}/bin/buf completion bash)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      ${pkgs.buf}/bin/buf completion fish | source
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      eval "$(${pkgs.buf}/bin/buf completion zsh)"
    '';
  };
}
