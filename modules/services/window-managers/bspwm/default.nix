{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.bspwm;
  bspwm = cfg.package;

  camelToSnake = s:
    builtins.replaceStrings lib.upperChars (map (c: "_${c}") lib.lowerChars) s;

  formatConfig = n: v:
    let
      formatList = x:
        if isList x
        then throw "can not convert 2-dimensional lists to bspwm format"
        else formatValue x;

      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else if isList v then concatMapStringsSep ", " formatList v
        else if isString v then "${lib.strings.escapeShellArg v}"
        else toString v;
    in
      "bspc config ${n} ${formatValue v}";

  formatMonitors = n: v: "bspc monitor ${n} -d ${concatStringsSep " " v}";

  formatRules = target: directiveOptions:
    let
      formatDirective = n: v:
        if isBool v then (if v then "${camelToSnake n}=on" else "${camelToSnake n}=off")
        else if (n == "desktop" || n == "node") then "${camelToSnake n}='${v}'"
        else "${camelToSnake n}=${lib.strings.escapeShellArg v}";

      directives = filterAttrs (n: v: v != null && !(lib.strings.hasPrefix "_" n)) directiveOptions;
      directivesStr = builtins.concatStringsSep " " (mapAttrsToList formatDirective directives);
    in
      "bspc rule -a ${target} ${directivesStr}";

  formatStartupPrograms = map (s: "${s} &");

in

{
  options = import ./options.nix { inherit pkgs; inherit lib; };

  config = mkIf cfg.enable {
    home.packages = [ bspwm ];
    xsession.windowManager.command =
      let
        configFile = pkgs.writeShellScript "bspwmrc" (
          concatStringsSep "\n" (
            (mapAttrsToList formatMonitors cfg.monitors)
            ++ (mapAttrsToList formatConfig cfg.settings)
            ++ (mapAttrsToList formatRules cfg.rules)
            ++ [ ''
              # java gui fixes
              export _JAVA_AWT_WM_NONREPARENTING=1
              bspc rule -a sun-awt-X11-XDialogPeer state=floating
            '' ]
            ++ [ cfg.extraConfig ]
            ++ (formatStartupPrograms cfg.startupPrograms)
          )
        );
        configCmdOpt = optionalString (cfg.settings != null) "-c ${configFile}";
      in
        "${cfg.package}/bin/bspwm ${configCmdOpt}";
  };
}
