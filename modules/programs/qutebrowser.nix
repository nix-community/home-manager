{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.qutebrowser;

  formatLine = o: n: v:
    let
      formatValue = v:
        if builtins.isNull v then
          "None"
        else if builtins.isBool v then
          (if v then "True" else "False")
        else if builtins.isString v then
          ''"${v}"''
        else if builtins.isList v then
          "[${concatStringsSep ", " (map formatValue v)}]"
        else
          builtins.toString v;
    in if builtins.isAttrs v then
      concatStringsSep "\n" (mapAttrsToList (formatLine "${o}${n}.") v)
    else
      "${o}${n} = ${formatValue v}";

in {
  options.programs.qutebrowser = {
    enable = mkEnableOption "qutebrowser";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Options to add to qutebrowser <filename>config.py</filename> file.
        See <link xlink:href="https://qutebrowser.org/doc/help/settings.html"/>
        for options.
      '';
      example = literalExample ''
        {
          colors = {
            hints = {
              bg = "#000000";
              fg = "#ffffff";
            };
            tabs.bar.bg = "#000000";
          };
          tabs.tabs_are_windows = true;
        }
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to qutebrowser <filename>config.py</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.qutebrowser ];

    xdg.configFile."qutebrowser/config.py".text = concatStringsSep "\n" ([ ]
      ++ mapAttrsToList (formatLine "c.") cfg.settings
      ++ optional (cfg.extraConfig != "") cfg.extraConfig);
  };
}
