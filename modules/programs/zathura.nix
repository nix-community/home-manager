{ config, lib, pkgs, ...}:

with lib;

let

  cfg = config.programs.zathura;

  formatLine = n: v:
    let
      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else toString v;
    in
      "set ${n}\t\"${formatValue v}\"";
in

{
  meta.maintainers = [maintainers.rprospero];

  options.programs.zathura = {
    enable = mkEnableOption ''
      Zathura, a highly customizable and funtional document viewer
      focused on keyboard interaction '';
    options = mkOption {
      default = {};
      type = with types; attrsOf (either str (either bool int));
      description = ''
        Add :set command options to zathura and make them permanent.
        See
        <citerefentry>
          <refentrytitle>zathurarc</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>
        to see the full list of options
      '';
      example = {default-bg = "#000000"; default-fg = "#FFFFFF";};
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional commands for zathura the zathurarc file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zathura ];
    xdg.configFile."zathura/zathurarc".text =
      concatStringsSep "\n" ([]
        ++ optional (cfg.extraConfig != "") cfg.extraConfig
        ++ mapAttrsToList formatLine cfg.options
      ) + "\n";
  };
}
