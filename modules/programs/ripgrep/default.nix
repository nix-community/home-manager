{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ripgrep;
in
{
  meta.maintainers = [
    lib.maintainers.khaneliman
    lib.hm.maintainers.pedorich-n
  ];

  options = {
    programs.ripgrep = {
      enable = lib.mkEnableOption "Ripgrep";

      package = lib.mkPackageOption pkgs "ripgrep" { nullable = true; };

      arguments = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [
          "--max-columns-preview"
          "--colors=line:style:bold"
        ];
        description = ''
          List of arguments to pass to ripgrep. Each item is given to ripgrep as
          a single command line argument verbatim.

          See <https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file>
          for an example configuration.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home =
      let
        configPath = "${config.xdg.configHome}/ripgrep/ripgreprc";
      in
      lib.mkMerge [
        { packages = lib.mkIf (cfg.package != null) [ cfg.package ]; }
        (lib.mkIf (cfg.arguments != [ ]) {
          file."${configPath}".text = lib.concatLines cfg.arguments;

          sessionVariables."RIPGREP_CONFIG_PATH" = configPath;
        })
      ];
  };
}
