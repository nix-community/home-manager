{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.bspwm;

  camelToSnake =
    builtins.replaceStrings upperChars (map (c: "_${c}") lowerChars);

  formatMonitor = monitor: desktops:
    "bspc monitor ${strings.escapeShellArg monitor} -d ${
      strings.escapeShellArgs desktops
    }";

  formatSetting = n: v:
    let
      vStr = if isBool v then
        boolToString v
      else if isInt v || isFloat v then
        toString v
      else if isString v then
        strings.escapeShellArg v
      else
        throw "unsupported setting type for ${n}";
    in "bspc config ${strings.escapeShellArg n} ${vStr}";

  formatRule = target: directives:
    let
      formatDirective = n: v:
        let
          vStr = if isBool v then
            if v then "on" else "off"
          else if isInt v || isFloat v then
            toString v
          else if isString v then
            v
          else
            throw "unsupported rule attribute type for ${n}";
        in "${camelToSnake n}=${vStr}";

      directivesStr = strings.escapeShellArgs (mapAttrsToList formatDirective
        (filterAttrs (n: v: v != null) directives));
    in "bspc rule -a ${strings.escapeShellArg target} ${directivesStr}";

  formatStartupProgram = s: "${s} &";

in {
  meta.maintainers = [ maintainers.ncfavier ];

  options = import ./options.nix { inherit pkgs lib; };

  config = mkIf cfg.enable {
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
