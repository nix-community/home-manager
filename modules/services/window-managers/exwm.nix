{
  config,
  lib,
  pkgs,
  ...
}:
{
  meta.maintainers = [ lib.hm.maintainers.garklein ];

  options = {
    xsession.windowManager.exwm = {
      enable = lib.mkEnableOption "exwm";

      loadScript = lib.mkOption {
        default = "(require 'exwm)";
        type = lib.types.lines;
        example = ''
          (require 'exwm)
          (exwm-enable)
        '';
        description = ''
          Emacs lisp code to be run after loading the user's init
          file.
        '';
      };

      package = lib.mkPackageOption pkgs "emacs" {
        example = [ "emacs-gtk" ];
      };

      extraPackages = lib.mkOption {
        type = lib.types.functionTo (lib.types.listOf lib.types.package);
        default = _epkgs: [ ];
        defaultText = lib.literalExpression "epkgs: []";
        example = lib.literalExpression ''
          epkgs: [
            epkgs.emms
            epkgs.magit
            epkgs.proof-general
          ]
        '';
        description = ''
          Extra packages available to Emacs. The value must be a
          function which receives the attrset defined in
          {var}`emacs.pkgs` as the sole argument.
        '';
      };
    };
  };

  config =
    let
      cfg = config.xsession.windowManager.exwm;
      exwm-emacs = cfg.package.pkgs.withPackages (epkgs: cfg.extraPackages epkgs ++ [ epkgs.exwm ]);
    in
    lib.mkIf cfg.enable {
      home.packages = [ exwm-emacs ];
      xsession.windowManager.command = ''
        ${exwm-emacs}/bin/emacs -l ${pkgs.writeText "emacs-exwm-load" "${cfg.loadScript}"}
      '';
    };
}
