{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.visidata;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.visidata = {
    enable = mkEnableOption "Visidata";
    package = mkPackageOption pkgs "visidata" { nullable = true; };
    visidatarc = mkOption {
      type = types.lines;
      default = "";
      example = ''
        options.min_memory_mb=100  # stop processing without 100MB free

        bindkey('0', 'go-leftmost')   # alias '0' to go to first column, like vim

        def median(values):
            L = sorted(values)
            return L[len(L)//2]

        vd.aggregator('median', median)
      '';
      description = ''
        Configuration settings and Python function declarations
        to be written to ~/.visidatarc. All available options
        can be found here: <https://www.visidata.org/docs/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".visidatarc" = mkIf (cfg.visidatarc != "") { text = cfg.visidatarc; };
  };
}
