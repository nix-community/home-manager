modulePath:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

in {
  nixpkgs.overlays = [
    (self: super: {
      "${cfg.wrappedPackageName}-unwrapped" =
        pkgs.runCommandLocal "${cfg.wrappedPackageName}-0" {
          meta.description = "I pretend to be ${cfg.name}";
          passthru.gtk3 = null;
        } ''
          mkdir -p "$out"/{bin,lib}
          touch "$out/bin/${cfg.wrappedPackageName}"
          chmod 755 "$out/bin/${cfg.wrappedPackageName}"
        '';

      chrome-gnome-shell =
        pkgs.runCommandLocal "dummy-chrome-gnome-shell" { } ''
          mkdir -p $out/lib/mozilla/native-messaging-hosts
          touch $out/lib/mozilla/native-messaging-hosts/dummy
        '';
    })
  ];
}
