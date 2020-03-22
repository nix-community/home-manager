{ config, lib, pkgs, ... }:

with lib; {
  imports = let
    old = n: [ "services" "compton" n ];
    new = n: [ "services" "picom" n ];
  in [
    (mkRenamedOptionModule (old "activeOpacity") (new "activeOpacity"))
    (mkRenamedOptionModule (old "backend") (new "backend"))
    (mkRenamedOptionModule (old "blur") (new "blur"))
    (mkRenamedOptionModule (old "blurExclude") (new "blurExclude"))
    (mkRenamedOptionModule (old "extraOptions") (new "extraOptions"))
    (mkRenamedOptionModule (old "fade") (new "fade"))
    (mkRenamedOptionModule (old "fadeDelta") (new "fadeDelta"))
    (mkRenamedOptionModule (old "fadeExclude") (new "fadeExclude"))
    (mkRenamedOptionModule (old "fadeSteps") (new "fadeSteps"))
    (mkRenamedOptionModule (old "inactiveDim") (new "inactiveDim"))
    (mkRenamedOptionModule (old "inactiveOpacity") (new "inactiveOpacity"))
    (mkRenamedOptionModule (old "menuOpacity") (new "menuOpacity"))
    (mkRenamedOptionModule (old "noDNDShadow") (new "noDNDShadow"))
    (mkRenamedOptionModule (old "noDockShadow") (new "noDockShadow"))
    (mkRenamedOptionModule (old "opacityRule") (new "opacityRule"))
    (mkRenamedOptionModule (old "package") (new "package"))
    (mkRenamedOptionModule (old "refreshRate") (new "refreshRate"))
    (mkRenamedOptionModule (old "shadow") (new "shadow"))
    (mkRenamedOptionModule (old "shadowExclude") (new "shadowExclude"))
    (mkRenamedOptionModule (old "shadowOffsets") (new "shadowOffsets"))
    (mkRenamedOptionModule (old "shadowOpacity") (new "shadowOpacity"))
    (mkChangedOptionModule (old "vSync") (new "vSync") (v: v != "none"))
  ];

  options.services.compton.enable = mkEnableOption "Compton X11 compositor" // {
    visible = false;
  };

  config = mkIf config.services.compton.enable {
    warnings = [
      "Obsolete option `services.compton.enable' is used. It was renamed to `services.picom.enable'."
    ];

    services.picom.enable = true;
  };
}
