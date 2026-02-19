{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rizin;
in
{
  meta.maintainers = [
    lib.hm.maintainers.rsahwe
  ];

  options = {
    programs.rizin = {
      enable = lib.mkEnableOption "Rizin";

      package = lib.mkPackageOption pkgs "rizin" { nullable = true; };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          e asm.bytes=true
          e asm.bytes.space=true
        '';
        description = ''
          Run configuration written to {file}`rizinrc`.
          See <https://book.rizin.re/src/configuration/initial_scripts.html>
          for more information.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."rizin/rizinrc" = lib.mkIf (cfg.extraConfig != "") {
      text = cfg.extraConfig;
    };
  };
}
