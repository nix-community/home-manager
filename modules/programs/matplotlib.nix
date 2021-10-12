{ config, lib, ... }:

with lib;

let

  cfg = config.programs.matplotlib;

  formatLine = o: n: v:
    let
      formatValue = v:
        if isBool v then (if v then "True" else "False") else toString v;
    in if isAttrs v then
      concatStringsSep "\n" (mapAttrsToList (formatLine "${o}${n}.") v)
    else
      (if v == "" then "" else "${o}${n}: ${formatValue v}");

in {
  meta.maintainers = [ maintainers.rprospero ];

  options.programs.matplotlib = {
    enable = mkEnableOption "matplotlib, a plotting library for python";

    config = mkOption {
      default = { };
      type = types.attrsOf types.anything;
      description = ''
        Add terms to the <filename>matplotlibrc</filename> file to
        control the default matplotlib behavior.
      '';
      example = literalExpression ''
        {
          backend = "Qt5Agg";
          axes = {
            grid = true;
            facecolor = "black";
            edgecolor = "FF9900";
          };
          grid.color = "FF9900";
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional commands for matplotlib that will be added to the
        <filename>matplotlibrc</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."matplotlib/matplotlibrc".text = concatStringsSep "\n" ([ ]
      ++ mapAttrsToList (formatLine "") cfg.config
      ++ optional (cfg.extraConfig != "") cfg.extraConfig) + "\n";
  };
}
