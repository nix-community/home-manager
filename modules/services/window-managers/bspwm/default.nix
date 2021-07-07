{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.bspwm;

  camelToSnake =
    builtins.replaceStrings upperChars (map (c: "_${c}") lowerChars);

  formatMonitor = monitor: desktops:
    "bspc monitor ${escapeShellArg monitor} -d ${escapeShellArgs desktops}";

  formatValue = v:
    if isList v then
      concatMapStringsSep "," formatValue v
    else if isBool v then
      if v then "on" else "off"
    else if isInt v || isFloat v then
      toString v
    else if isString v then
      v
    else
      throw "unsupported type"; # should not happen

  formatSetting = n: v: "bspc config ${escapeShellArgs [ n (formatValue v) ]}";

  formatRule = target: directives:
    let
      formatDirective = n: v: "${camelToSnake n}=${formatValue v}";

      directivesStr = escapeShellArgs (mapAttrsToList formatDirective
        (filterAttrs (n: v: v != null) directives));
    in "bspc rule -a ${escapeShellArg target} ${directivesStr}";

  formatStartupProgram = s: "${s} &";

in {
  meta.maintainers = [ maintainers.ncfavier ];

  options = import ./options.nix { inherit pkgs lib; };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "xsession.windowManager.bspwm" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."bspwm/bspwmrc".source = pkgs.writeShellScript "bspwmrc" ''
      ${concatStringsSep "\n" (mapAttrsToList formatMonitor cfg.monitors)}

      ${concatStringsSep "\n" (mapAttrsToList formatSetting cfg.settings)}

      bspc rule -r '*'
      ${concatStringsSep "\n" (mapAttrsToList formatRule cfg.rules)}

      # java gui fixes
      export _JAVA_AWT_WM_NONREPARENTING=1
      bspc rule -a sun-awt-X11-XDialogPeer state=floating

      ${cfg.extraConfig}
      ${concatMapStringsSep "\n" formatStartupProgram cfg.startupPrograms}
    '';

    xsession.windowManager.command =
      "${cfg.package}/bin/bspwm -c ${config.xdg.configHome}/bspwm/bspwmrc";
  };
}
