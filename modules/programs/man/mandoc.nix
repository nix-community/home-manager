{ config, lib, ... }:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.programs.man;
  cfgManDoc = config.programs.man.mandoc;
in
{
  meta.maintainers = [ lib.maintainers.thiagokokada ];

  options.programs.man.mandoc.enable = mkEnableOption "mandoc as the man page viewer";

  config = mkIf (cfg.enable && cfgManDoc.enable) {
    home.extraProfileCommands = lib.mkIf (cfg.generateCaches && cfg.package != null) ''
      if [ -d "$out/share/man" ]; then
        ${lib.getExe' cfg.package "makewhatis"} -T utf8 "$out/share/man"
      fi
    '';

    xdg.dataFile."mandoc/man".source = config.home.path + "/share/man";

    home.sessionSearchVariables.MANPATH = lib.mkBefore [ "${config.xdg.dataHome}/mandoc/man" ];
  };
}
