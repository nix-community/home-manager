{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.matplotlib;

  formatLine = o: n: v:
    let
      formatValue = v:
        if lib.isBool v then (if v then "True" else "False") else toString v;
    in if lib.isAttrs v then
      lib.concatStringsSep "\n" (lib.mapAttrsToList (formatLine "${o}${n}.") v)
    else
      (if v == "" then "" else "${o}${n}: ${formatValue v}");

in {
  meta.maintainers = [ lib.maintainers.rprospero ];

  options.programs.matplotlib = {
    enable = lib.mkEnableOption "matplotlib, a plotting library for python";

    config = mkOption {
      default = { };
      type = types.attrsOf types.anything;
      description = ''
        Add terms to the {file}`matplotlibrc` file to
        control the default matplotlib behavior.
      '';
      example = lib.literalExpression ''
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
        {file}`matplotlibrc` file.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."matplotlib/matplotlibrc".text = lib.concatStringsSep "\n"
      ([ ] ++ lib.mapAttrsToList (formatLine "") cfg.config
        ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig) + "\n";
  };
}
