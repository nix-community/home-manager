{ pkgs, config, lib, ... }:
let
  inherit (lib)
    mkEnableOption mkPackageOption types literalExpression mkIf maintainers;
  cfg = config.programs.mergiraf;
  mergiraf = "${cfg.package}/bin/mergiraf";
in {
  meta.maintainers = [ maintainers.bobvanderlinden ];

  options = {
    programs.mergiraf = {
      enable = mkEnableOption "mergiraf";
      package = mkPackageOption pkgs "mergiraf" { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.git = {
      attributes = [ "* merge=mergiraf" ];
      extraConfig = {
        merge.mergiraf = {
          name = "mergiraf";
          driver =
            "${mergiraf} merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
        };
      };
    };
  };
}
