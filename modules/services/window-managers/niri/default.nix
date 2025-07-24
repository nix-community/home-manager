{
  lib,
  pkgs,
  config,
  ...
}:

let
  cfg = config.wayland.windowManager.niri;

  kdl = pkgs.formats.kdl { version = 1; };

  validated-config =
    pkgs.runCommandLocal "config.kdl"
      {
        config = cfg.configFile;
        nativeBuildInputs = [
          cfg.package
        ];
      }
      ''
        niri validate -c $config
        cp $config $out
      '';
in
{
  meta.maintainers = [ lib.maintainers.sodiboo ];

  imports = [
  ];

  options.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "niri, a scrollable-tiling Wayland compositor";

    package = lib.mkPackageOption pkgs "niri" { };

    configFile = lib.mkOption {
      description = ''
        The config file to place in your home directory.

        Takes priority over all other configuration options.
      '';
      type = lib.types.path;
      default = kdl.generate "config.kdl" cfg.rendered;
      defaultText = lib.literalExpression ''
        Generated from the rest of this module.
      '';
    };

    rendered = lib.mkOption {
      type = kdl.type;
      visible = false;
      internal = true;
      readOnly = true;

      default = [
        cfg.extraConfig
      ];
    };

    extraConfig = lib.mkOption {
      type = kdl.type;
      default = [ ];
      description = ''
        Extra toplevel configuration to append to niri's config file.

        See https://github.com/NixOS/nixpkgs/pull/426828
      '';

      example = lib.literalExpression ''
        [
          (node null "input" [] {} [
            (node null "keyboard" [] {} [
              (node null "xkb" [] {} [
                (node null "layout" ["no"] {} [])
              ])
            ])
          ])
          (node null "output" ["eDP-1"] {} [
            (node null "mode" ["2560x1440"] {} [])
          ])
          (node null "output" ["HDMI-A-1"] {} [
            (node null "mode" ["1920x1080"] {} [])
          ])
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."niri/config.kdl".source = validated-config;
  };
}
