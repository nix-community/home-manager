# Modular Services {#sec-usage-modular-services}

Home Manager supports nixpkgs
[modular services](https://nixos.org/manual/nixos/unstable/#modular-services)
under [](#opt-home.services). This is the home-manager analog to the
NixOS `system.services` namespace: each entry is an abstract service
sourced from `<nixpkgs/lib/services/lib.nix>` with the upstream portable
systemd module loaded into it, so service modules shipped with packages
(e.g. `pkgs.<name>.passthru.services.default`) drop in unchanged --
the same module evaluates on NixOS and on Home Manager.

A minimal example -- run a one-shot user service from a package's
modular service definition:

```nix
{ pkgs, ... }: {
  home.services.tunnel = {
    imports = [ pkgs.ghostunnel.passthru.services.default ];
    ghostunnel = {
      listen = "127.0.0.1:8443";
      target = "127.0.0.1:8080";
      cert = "/run/secrets/cert.pem";
      key = "/run/secrets/key.pem";
      allowAll = true;
    };
  };
}
```

This produces `~/.config/systemd/user/tunnel.service` with the expected
`ExecStart`, `LoadCredential`, and `WantedBy=default.target`.

Each service exposes the upstream NixOS-style schema: [`process.argv`],
`systemd.lib`, `systemd.mainExecStart`, `systemd.service`,
`systemd.services`, `systemd.sockets`. Lifted units are translated from
NixOS-style attrs (`wantedBy`, `serviceConfig`, `unitConfig`,
`environment`, ...) into the section-based INI shape
(`{ Unit; Service; Install; }`) that home-manager's
[](#opt-systemd.user.services) consumes. Only common keys are mapped
explicitly; uncommon options remain reachable via `unitConfig`,
`serviceConfig`, or `socketConfig`.

Sub-services (nested `services.<sub>` inside another service) and their
units are dashed under the parent service name. The empty unit key
`""` denotes the service's *primary* unit (lifted to a unit named
after the service itself); [`process.argv`] becomes the default
`ExecStart` for that unit, which defaults to `WantedBy=default.target`.

## Configuration data {#sec-usage-modular-services-configdata}

Each service can declare configuration files via `configData.<name>`.
These are materialized at `$XDG_CONFIG_HOME/system-services/<service>/<name>`
(mirroring how NixOS lifts `configData` to `environment.etc`), with the
absolute path injected back into `configData.<name>.path` so the service
can refer to its files at a stable location:

```nix
{ config, ... }:
{
  home.services.demo = {
    process.argv = [ "/bin/myapp" "--config" config.home.services.demo.configData."app.toml".path ];
    configData."app.toml".text = ''
      port = 1234
    '';
  };
}
```

## Scope notes {#sec-usage-modular-services-scope}

Home Manager mirrors the surface of nixpkgs' portable systemd module:
services and sockets only. Other unit kinds Home Manager supports
natively under [](#opt-systemd.user.services) (timers, paths, mounts, ...)
are intentionally not modeled on `home.services` until upstream grows them,
to keep both surfaces aligned.

[`process.argv`]: https://nixos.org/manual/nixos/unstable/#service-opt-process.argv
