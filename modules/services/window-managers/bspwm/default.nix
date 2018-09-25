{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.bspwm;
  bspwm = cfg.package;

  formatConfig = n: v:
    let
      formatList = x:
        if isList x
        then throw "can not convert 2-dimensional lists to bspwm format"
        else formatValue x;

      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else if isList v then concatMapStringsSep ", " formatList v
        else toString v;
    in
      "bspc config ${n} ${formatValue v}";

  formatMonitors = n:
    map(s: 
      "bspc monitor " + (if (builtins.hasAttr "name" s) then (s.name + " ") else "") + "-d ${concatStringsSep " " s.desktops}" 
    ) n;

  formatRules = n:
    let
      camelToSnake = s:
        builtins.replaceStrings lib.upperChars (map (c: "_${c}") lib.lowerChars) s;

      formatDirective = n: v:
        if isBool v then (if v then "${camelToSnake n}=on" else "${camelToSnake n}=off")
        else if n == "desktop" then "${camelToSnake n}='${v}'"
        else "${camelToSnake n}=${toString v}";

    in
    map(s:
      "bspc rule -a " +
        (if (s.instanceName != null) then ("'${s.className}:${s.instanceName}'") else (s.className)) +
        builtins.concatStringsSep " " (map (n:
          (if n != "className" && n != "instanceName" && n != null then (formatDirective n s.${n}) else (""))
        ) (builtins.attrNames s))
  ) n;

  formatStartupPrograms = n:
    map(s: s + " &") n;

in

{
  options = import ./options.nix { inherit pkgs; inherit lib; };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ bspwm ];
      xsession.windowManager.command = "${cfg.package}/bin/bspwm";
    }

    (mkIf (cfg.config != null) {
      xdg.configFile."bspwm/bspwmrc" = {
        executable = true;
        text = "#!/bin/sh\n\n" + 
        concatStringsSep "\n" ([]
          ++ (optionals (cfg.monitors != []) (formatMonitors cfg.monitors))
          ++ [ "" ]
          ++ (optionals (cfg.config != null) (mapAttrsToList formatConfig cfg.config))
          ++ [ "" ]
          # ++ (optionals (cfg.rules != []) (formatRules cfg.rules))
          ++ [ "" ]
          ++ (optional (cfg.extraConfig != "") cfg.extraConfig)
          ++ (optionals (cfg.startupPrograms != null) (formatStartupPrograms cfg.startupPrograms))
        ) + "\n";
      };
    })
  ]);
}
