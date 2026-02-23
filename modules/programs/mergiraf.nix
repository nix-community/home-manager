{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkIf
    maintainers
    ;
  cfg = config.programs.mergiraf;
in
{
  meta.maintainers = [ maintainers.bobvanderlinden ];

  options = {
    programs.mergiraf = {
      enable = mkEnableOption "mergiraf";

      package = mkPackageOption pkgs "mergiraf" { };
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      programs = {
        git = {
          attributes = [ "* merge=mergiraf" ];
          settings = {
            merge = {
              mergiraf = {
                name = "mergiraf";
                driver = "${lib.getExe cfg.package} merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
              };
              conflictStyle = "diff3";
            };
          };
        };

        jujutsu = {
          settings = {
            ui = {
              # Rely on the built-in configuration
              merge-editor = "mergiraf";
            };
            # Explicitly set the path to the package
            merge-tools = {
              mergiraf = {
                program = lib.getExe cfg.package;
              };
            };
          };
        };
      };
    })
  ];
}
