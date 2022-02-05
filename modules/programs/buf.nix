{ config, lib, pkgs, ... }:

let
  cfg = config.programs.buf;
in {
  meta.maintainers = [ lib.maintainers.lucperkins ];

  options.programs.buf = {
    enable = lib.mkEnableOption "The Buf CLI tool";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.buf;
      defaultText = lib.literalExpression "pkgs.buf";
      description = "Package providing <command>buf</command>.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
  };
}
