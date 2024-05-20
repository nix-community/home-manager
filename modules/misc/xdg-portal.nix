{ config, pkgs, lib, ... }:

let

  inherit (lib) mkIf mkMerge mkOption optional types;

  associationOptions = with types;
    attrsOf (coercedTo (either (listOf str) str)
      (x: lib.concatStringsSep ";" (lib.toList x)) str);

in {
  meta.maintainers = [ lib.maintainers.misterio77 ];

  options.xdg.portal = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to enable [XDG desktop integration](https://github.com/flatpak/xdg-desktop-portal).

        Note, if you use the NixOS module and have `useUserPackages = true`,
        make sure to add

        ``` nix
        environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
        ```

        to your system configuration so that the portal definitions and DE
        provided configurations get linked.
      '';
    };

    extraPortals = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of additional portals that should be passed to the
        `xdg-desktop-portal.service`, via the `XDG_DESKTOP_PORTAL_DIR`
        variable.

        Portals allow interaction with system, like choosing files or taking
        screenshots. At minimum, a desktop portal implementation should be
        listed.
      '';
    };

    xdgOpenUsePortal = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Sets environment variable `NIXOS_XDG_OPEN_USE_PORTAL` to `1`
        This will make `xdg-open` use the portal to open programs, which resolves bugs involving
        programs opening inside FHS envs or with unexpected env vars set from wrappers.
        See [#160923](https://github.com/NixOS/nixpkgs/issues/160923) for more info.
      '';
    };

    config = mkOption {
      type = types.attrsOf associationOptions;
      default = { };
      example = {
        x-cinnamon = { default = [ "xapp" "gtk" ]; };
        pantheon = {
          default = [ "pantheon" "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
        common = { default = [ "gtk" ]; };
      };
      description = ''
        Sets which portal backend should be used to provide the implementation
        for the requested interface. For details check {manpage}`portals.conf(5)`.

        These will be written with the name `$desktop-portals.conf` for
        `xdg.portal.config.$desktop` and `portals.conf` for
        `xdg.portal.config.common` as an exception.

        These, together with `xdg.portal.configPackages`, will be joined into a
        directory and passed to `xdg-desktop-portal.service` through a
        `NIXOS_XDG_DESKTOP_PORTAL_CONFIG_DIR` variable.
      '';
    };

    configPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.gnome.gnome-session ]";
      description = ''
        List of packages that provide XDG desktop portal configuration, usually in
        the form of `share/xdg-desktop-portal/$desktop-portals.conf`.

        Note that configs in `xdg.portal.config` will be preferred if set.
      '';
    };
  };

  config = let
    cfg = config.xdg.portal;
    packages = [ pkgs.xdg-desktop-portal ] ++ cfg.extraPortals;
    portalsDir =
      "${config.home.profileDirectory}/share/xdg-desktop-portal/portals";
  in mkIf cfg.enable {
    warnings = optional (cfg.configPackages == [ ] && cfg.config == { }) ''
      xdg-desktop-portal 1.17 reworked how portal implementations are loaded, you
      should either set `xdg.portal.config` or `xdg.portal.configPackages`
      to specify which portal backend to use for the requested interface.

      https://github.com/flatpak/xdg-desktop-portal/blob/1.18.1/doc/portals.conf.rst.in

      If you simply want to keep the behaviour in < 1.17, which uses the first
      portal implementation found in lexicographical order, use the following:

      xdg.portal.config.common.default = "*";
    '';

    assertions = [
      (lib.hm.assertions.assertPlatform "xdg.portal" pkgs lib.platforms.linux)

      {
        assertion = cfg.extraPortals != [ ];
        message =
          "Setting xdg.portal.enable to true requires a portal implementation in xdg.portal.extraPortals such as xdg-desktop-portal-gtk or xdg-desktop-portal-kde.";
      }
    ];

    home = {
      packages = packages ++ cfg.configPackages;
      sessionVariables = mkMerge [
        (mkIf cfg.xdgOpenUsePortal { NIXOS_XDG_OPEN_USE_PORTAL = "1"; })
        { NIX_XDG_DESKTOP_PORTAL_DIR = portalsDir; }
      ];
    };
    systemd.user.sessionVariables = {
      NIX_XDG_DESKTOP_PORTAL_DIR = portalsDir;
    };

    xdg.configFile = lib.concatMapAttrs (desktop: conf:
      lib.optionalAttrs (conf != { }) {
        "xdg-desktop-portal/${
          lib.optionalString (desktop != "common") "${desktop}-"
        }portals.conf".text = lib.generators.toINI { } { preferred = conf; };
      }) cfg.config;
  };
}
