# Per-service extension module loaded into every `home.services` entry.
#
# Re-exports the nixpkgs portable systemd service module so HM modular
# services accept the same NixOS-style schema (`systemd.lib`,
# `systemd.mainExecStart`, `systemd.service`, `systemd.services`,
# `systemd.sockets`) as their NixOS counterparts. This is what lets
# upstream service modules (e.g. `pkgs.<name>.passthru.services.default`)
# drop in unchanged. Then overrides the primary unit's `wantedBy` default
# to `default.target`, since user units typically attach to that instead
# of `multi-user.target`.
{ lib, nixpkgsPath, ... }:
{
  imports = [
    (nixpkgsPath + "/nixos/modules/system/service/systemd/service.nix")
  ];

  # The empty key `""` is the modular service's *primary* unit (see
  # `dashed` in `default.nix`).
  config.systemd.services."" = {
    wantedBy = lib.mkOverride 950 [ "default.target" ];
  };
}
