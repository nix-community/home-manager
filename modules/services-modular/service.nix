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
#
# Non-module arguments, matching nixpkgs' `lib/services` convention: keeping
# `pkgs` out of the module arguments is what lets service modules stay
# portable.
{ pkgs }:

{ lib, ... }:
let
  servicePath = pkgs.path + "/nixos/modules/system/service/systemd/service.nix";

  # nixpkgs has shipped this file both as a plain module and wrapped in a
  # `{ pkgs }:` non-module-arguments closure (see nixpkgs `541a6f371`,
  # reverted in `ec69cf3f7`). The module system cannot apply such a closure
  # itself, so pick the shape at import time instead of assuming one. The
  # plain module always declares `config`; the closure declares `pkgs` and no
  # module arguments.
  nonModuleArgs = lib.functionArgs (import servicePath);
  isWrapped = nonModuleArgs ? pkgs && !(nonModuleArgs ? config);

  serviceModule =
    if isWrapped then
      # `importApply` preserves `_file`, so module-system errors keep pointing
      # at the nixpkgs file. `intersectAttrs` passes only the arguments the
      # closure actually declares, so a closed `{ pkgs }` pattern is satisfied
      # exactly while a hypothetical `{ pkgs, lib }` also works.
      lib.modules.importApply servicePath (lib.intersectAttrs nonModuleArgs { inherit lib pkgs; })
    else
      servicePath;
in
{
  imports = [ serviceModule ];

  # The empty key `""` is the modular service's *primary* unit (see
  # `dashed` in `default.nix`).
  config.systemd.services."" = {
    wantedBy = lib.mkOverride 950 [ "default.target" ];
  };
}
