{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.buf;
in {
  meta.maintainers = [ maintainers.lucperkins ];

  options.programs.buf = {
    enable = mkEnableOption "The Buf CLI tool";

    package = mkOption {
      type = types.package;
      default = pkgs.buf;
      defaultText = literalExpression "pkgs.buf";
      description = "Package providing <command>buf</command>.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
