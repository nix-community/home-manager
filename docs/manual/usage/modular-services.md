# Modular Services {#sec-usage-modular-services}

Home Manager supports nixpkgs
[modular services](https://nixos.org/manual/nixos/unstable/#modular-services)
under [](#opt-home.services). This is the Home Manager analog to the
NixOS `system.services` namespace: each entry is an abstract service
sourced from `<nixpkgs/lib/services/lib.nix>` with the upstream portable
systemd module loaded into it, so service modules shipped with packages
(e.g. `pkgs.<name>.passthru.services.default`) drop in unchanged --
the same module evaluates on NixOS and on Home Manager.

A minimal example -- run mpd as a user service:

```nix
{ pkgs, ... }: {
  home.services.mpd = {
    process.argv = [ "${pkgs.mpd}/bin/mpd" "--no-daemon" ];
  };
}
```

This produces `~/.config/systemd/user/mpd.service` with `ExecStart` set
to the mpd binary and `WantedBy=default.target`.

Each service exposes the upstream NixOS-style schema: [`process.argv`],
`systemd.lib`, `systemd.mainExecStart`, `systemd.service`,
`systemd.services`, `systemd.sockets`. Lifted units are translated from
NixOS-style attrs (`wantedBy`, `serviceConfig`, `unitConfig`,
`environment`, ...) into the section-based INI shape
(`{ Unit; Service; Install; }`) that Home Manager's
[](#opt-systemd.user.services) consumes. Only common keys are mapped
explicitly; uncommon options remain reachable via `unitConfig`,
`serviceConfig`, or `socketConfig`.

Sub-services (nested `services.<sub>` inside another service) and their
units are dashed under the parent service name. The empty unit key
`""` denotes the service's *primary* unit (lifted to a unit named
after the service itself); [`process.argv`] becomes the default
`ExecStart` for that unit, which defaults to `WantedBy=default.target`.

## Reusing upstream package modules {#sec-usage-modular-services-upstream}

Modular services exposed by packages under
`pkgs.<name>.passthru.services.default` can be imported directly.
For example, `pkgs.php`'s [`php-fpm`]:

```nix
{ pkgs, ... }: {
  home.services."php-fpm" = {
    imports = [ pkgs.php.passthru.services.default ];
    configData."php-fpm.conf".source = builtins.elemAt config.home.services.php-fpm.process.argv 2;
    php-fpm.settings.mypool = {
      listen = "127.0.0.1:9000";
      # FIXME: required by upstream modular service, but ignored when run as user
      "user" = "";
      "pm" = "dynamic";
      "pm.max_children" = 75;
      "pm.min_spare_servers" = 5;
      "pm.max_spare_servers" = 20;
    };
  };
}
```

Some packages ship modules written for system services that include
directives the user-session manager cannot honour (`DynamicUser`,
`AmbientCapabilities`, ...). The unit is still generated with those
directives -- user systemd silently ignores what it cannot apply.
`WantedBy=multi-user.target` is automatically normalized to
`WantedBy=default.target`. Other directives can be overridden per
service:

```nix
home.services."tunnel" = {
  imports = [ pkgs.ghostunnel.passthru.services.default ];
  # ...
  systemd.services."tunnel".serviceConfig.DynamicUser = lib.mkForce false;
};
```

## Configuration data {#sec-usage-modular-services-configdata}

Each service can declare configuration files via `configData.<name>`.
These are materialized at `$XDG_CONFIG_HOME/home-services/<service>/<name>`
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

The store paths of all enabled `configData` entries are automatically
added to the primary unit's `X-Reload-Triggers`, so `home-manager switch`
restarts the service whenever any of its configuration files change. To
reload instead of restart, override `X-SwitchMethod`:

```nix
home.services.demo.systemd.services."".unitConfig.X-SwitchMethod = "reload";
```

## Scope notes {#sec-usage-modular-services-scope}

Home Manager mirrors the surface of nixpkgs' portable systemd module:
services and sockets only. Other unit kinds Home Manager supports
natively under [](#opt-systemd.user.services) (timers, paths, mounts, ...)
are intentionally not modeled on `home.services` until upstream grows them,
to keep both surfaces aligned.

[`process.argv`]: https://nixos.org/manual/nixos/unstable/#service-opt-process.argv
[`php-fpm`]: https://nixos.org/manual/nixos/stable/options#opt-_imports_=___pkgs.php.services.default___
