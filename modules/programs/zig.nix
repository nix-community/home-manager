{ config, pkgs, lib, ... }:

with lib;

let

  cfg = config.programs.zig;

in {
  meta.maintainers = [ maintainers.luisnquin ];

  options = {
    programs.zig = {
      enable = mkEnableOption "zig";

      package = mkOption pkgs {
        type = types.package;
        default = pkgs.zig;
        defaultText = literalExpression "pkgs.zig";
        description = "The Zig package to use.";
      };

      enableZshIntegration = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Zig’s Zsh integration.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zsh.plugins = mkIf cfg.enableZshIntegration [{
      name = "zig-zsh-completions-plugin";
      file = "zig-shell-completions.plugin.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "ziglang";
        repo = "shell-completions";
        rev = "31d3ad12890371bf467ef7143f5c2f31cfa7b7c1";
        sha256 = "1fzl1x56b4m11wajk1az4p24312z7wlj2cqa3b519v30yz9clgr0";
      };
    }];
  };
}
