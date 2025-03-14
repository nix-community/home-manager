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
      extraConfig = {
        merge.mergiraf = {
          name = "mergiraf";
          driver =
            "${mergiraf} merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
        };
      };
    };

    xdg.configFile."git/attributes".source =
      pkgs.runCommand "mergiraf-git-attributes" { } ''
        ${mergiraf} languages --gitattributes > $out
      '';
  };
}
