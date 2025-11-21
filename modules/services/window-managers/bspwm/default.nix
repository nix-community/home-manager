{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    concatMapStringsSep
    mapAttrsToList
    concatStringsSep
    ;

  cfg = config.xsession.windowManager.bspwm;

  camelToSnake = builtins.replaceStrings lib.upperChars (map (c: "_${c}") lib.lowerChars);

  formatMonitor =
    monitor: desktops:
    let
      resetDesktops = "bspc monitor ${escapeShellArg monitor} -d ${escapeShellArgs desktops}";
      defaultDesktopName = "Desktop"; # https://github.com/baskerville/bspwm/blob/master/src/desktop.h
    in
    if cfg.alwaysResetDesktops then
      resetDesktops
    else
      ''
        if [[ $(bspc query --desktops --names --monitor ${escapeShellArg monitor}) == ${defaultDesktopName} ]]; then
          ${resetDesktops}
        fi'';

  formatValue =
    v:
    if lib.isList v then
      concatMapStringsSep "," formatValue v
    else if lib.isBool v then
      if v then "on" else "off"
    else if lib.isInt v || lib.isFloat v then
      toString v
    else if lib.isString v then
      v
    else
      throw "unsupported type"; # should not happen

  formatSetting =
    n: v:
    "bspc config ${
      escapeShellArgs [
        n
        (formatValue v)
      ]
    }";

  formatRule =
    target: directives:
    let
      formatDirective = n: v: "${camelToSnake n}=${formatValue v}";

      directivesStr = escapeShellArgs (
        mapAttrsToList formatDirective (lib.filterAttrs (n: v: v != null) directives)
      );
    in
    "bspc rule -a ${escapeShellArg target} ${directivesStr}";

  formatStartupProgram = s: "${s} &";

in
{
  meta.maintainers = [ lib.maintainers.ncfavier ];

  options = import ./options.nix { inherit pkgs lib; };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "xsession.windowManager.bspwm" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."bspwm/bspwmrc".source = pkgs.writeShellScript "bspwmrc" (
      (lib.optionalString (cfg.extraConfigEarly != "") (cfg.extraConfigEarly + "\n"))
      + ''
        ${concatStringsSep "\n" (mapAttrsToList formatMonitor cfg.monitors)}

        ${concatStringsSep "\n" (mapAttrsToList formatSetting cfg.settings)}

        bspc rule -r '*'
        ${concatStringsSep "\n" (mapAttrsToList formatRule cfg.rules)}

        # java gui fixes
        export _JAVA_AWT_WM_NONREPARENTING=1
        bspc rule -a sun-awt-X11-XDialogPeer state=floating

        ${cfg.extraConfig}
        ${concatMapStringsSep "\n" formatStartupProgram cfg.startupPrograms}
      ''
    );

    # for applications not started by bspwm, e.g. sxhkd
    xsession.profileExtra = ''
      # java gui fixes
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    xsession.windowManager.command = "${cfg.package}/bin/bspwm -c ${config.xdg.configHome}/bspwm/bspwmrc";
  };
}
