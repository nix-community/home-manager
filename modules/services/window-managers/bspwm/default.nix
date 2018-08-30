{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.windowManager.bspwm;
  bspwm = cfg.package;

  monitor = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The name or id of the monitor (MONITOR_SEL).";
        example = "HDMI-0";
      };

      desktops = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The desktops that the monitor is going to hold";
        example = [ "web" "terminal" "III" "IV" ];
      };
    };
  };

  rule = types.submodule {
    options = {
      className = mkOption {
        type = types.str;
        default = "";
        description = "The class name of the program you want to apply the rule";
        example = "Firefox";
      };

      instanceName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The particular instance name of a program";
        example = "Navigator";
      };

      monitor = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The monitor where the rule should be applied";
        example = "HDMI-0";
      };

      desktop = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The desktop where the rule should be applied";
        example = "^8";
      };

      # AAHFUIOEHFUIWEHFWUIEHFUIWEH
      node = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The node where the rule should be applied";
      };

      state = mkOption {
        type = types.nullOr (types.enum [ "tiled" "pseudo_tiled" "floating" "fullscreen" ]);
        default = null;
        description = "The state in where the window should be spawned";
        example = "floating";
      };

      layer = mkOption {
        type = types.nullOr (types.enum [ "below" "normal" "above" ]);
        default = null;
        description = "The layer where the window should be spawned";
        example = "above";
      };

      splitDir = mkOption {
        type = types.nullOr (types.enum [ "north" "west" "south" "east" ]);
        default = null;
        description = "The direction where the container is going to be splitted";
        example = "south";
      };

      # splitRatio = mkOption {
      #   type = types.nullOr types.float;
      #   default = null;
      #   description = "The ratio between the new window and the previous existing window in the desktop";
      #   example = 0.65;
      # };

      hidden = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node isn't going to occupy any space";
        example = true;
      };

      sticky = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to stay in the focused desktop of its monitor";
        example = true;
      };

      private = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to try to stay in the same tiling position and size";
        example = true;
      };

      locked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to ignore the 'node --close' messae";
        example = true;
      };

      marked = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the node is going to be marked for deferred actions";
        example = true;
      };

      # AIOFGHIEUWHGWUIEHGUIWEGHUIWE
      center = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "";
        example = true;
      };

      follow = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the previous focused node is going to stay focused";
        example = true;
      };

      # GVWIOERHGIOWERHGOWIERGHWIOEHGWIOEHGIOWERHGWO
      manage = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "";
        example = true;
      };

      focus = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the new node is going to gain the focus";
        example = true;
      };

      border = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "If it's set to true, the new node is going to have border";
        example = true;
      };
    };
  };

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
        (if (builtins.hasAttr "instanceName" s) then ("'${s.className}:${s.instanceName}'") else (s.className)) +
        builtins.concatStringsSep " " (map (n:
          (if n != "className" && n != "instanceName" then (formatDirective n s.${n}) else (""))
        ) (builtins.attrNames s))
  ) n;

  formatStartupPrograms = n:
    map(s: s + " &") n;

in

{
  options = import .options.nix{};

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
          ++ (optionals (cfg.rules != []) (formatRules cfg.rules))
          ++ [ "" ]
          ++ (optional (cfg.extraConfig != "") cfg.extraConfig)
          ++ (optionals (cfg.startupPrograms != null) (formatStartupPrograms cfg.startupPrograms))
        ) + "\n";
      };
    })
  ]);
}
