{
  pkgs,

  # Note, this should be "the standard library" + HM extensions.
  lib,

  # Whether to enable module type checking.
  check ? true,

  # If disabled, the pkgs attribute passed to this function is used instead.
  useNixpkgsModule ? true,
}:

let

  modules =
    [
      # keep-sorted start case=no numeric=yes
      ./accounts/calendar.nix
      ./accounts/contacts.nix
      ./accounts/email.nix
      ./config/home-cursor.nix
      ./config/i18n.nix
      ./dbus.nix
      ./files.nix
      ./home-environment.nix
      ./i18n/input-method/default.nix
      ./launchd/default.nix
      ./manual.nix
      ./misc/dconf.nix
      ./misc/debug.nix
      ./misc/editorconfig.nix
      ./misc/fontconfig.nix
      ./misc/gtk.nix
      ./misc/lib.nix
      ./misc/mozilla-messaging-hosts.nix
      ./misc/news.nix
      ./misc/nix.nix
      ./misc/nixgl.nix
      ./misc/numlock.nix
      ./misc/pam.nix
      ./misc/qt.nix
      ./misc/qt/kconfig.nix
      ./misc/shell.nix
      ./misc/specialisation.nix
      ./misc/submodule-support.nix
      ./misc/tmpfiles.nix
      ./misc/uninstall.nix
      ./misc/version.nix
      ./misc/vte.nix
      ./misc/xdg-autostart.nix
      ./misc/xdg-desktop-entries.nix
      ./misc/xdg-mime-apps.nix
      ./misc/xdg-mime.nix
      ./misc/xdg-portal.nix
      ./misc/xdg-system-dirs.nix
      ./misc/xdg-user-dirs.nix
      ./misc/xdg.nix
      ./misc/xfconf.nix
      ./systemd.nix
      ./targets/darwin
      ./targets/generic-linux.nix
      ./wayland.nix
      ./xresources.nix
      ./xsession.nix
      # keep-sorted end
      (pkgs.path + "/nixos/modules/misc/assertions.nix")
      (pkgs.path + "/nixos/modules/misc/meta.nix")

      (lib.mkRemovedOptionModule [ "services" "password-store-sync" ] ''
        Use services.git-sync instead.
      '')
      (lib.mkRemovedOptionModule [ "services" "keepassx" ] ''
        KeePassX is no longer maintained.
      '')
    ]
    ++ (lib.concatMap
      (
        dir:
        lib.pipe dir [
          builtins.readDir
          (lib.filterAttrs (_path: kind: kind == "directory"))
          (lib.mapAttrsToList (path: _kind: lib.path.append dir path))
        ]
      )
      [
        ./services
        ./programs
      ]
    )
    ++ lib.optional useNixpkgsModule ./misc/nixpkgs.nix
    ++ lib.optional (!useNixpkgsModule) ./misc/nixpkgs-disabled.nix;

  pkgsModule =
    { config, ... }:
    {
      config =
        {
          _module.args.baseModules = modules;
          _module.args.pkgsPath = lib.mkDefault (
            if lib.versionAtLeast config.home.stateVersion "20.09" then pkgs.path else <nixpkgs>
          );
          _module.args.pkgs = lib.mkDefault pkgs;
          _module.check = check;
          lib = lib.hm;
        }
        // lib.optionalAttrs useNixpkgsModule {
          nixpkgs.system = lib.mkDefault pkgs.stdenv.hostPlatform.system;
        };
    };

in
modules ++ [ pkgsModule ]
