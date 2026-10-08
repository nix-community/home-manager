{ config, ... }:
{
  time = "2026-06-18T13:00:50+00:00";
  condition =
    config.services.podman.enable
    && (
      config.services.podman.settings.registries.insecure != [ ]
      || config.services.podman.settings.registries.block != [ ]
    );
  message = ''
    `services.podman.settings.registries` now generates `registries.conf` v2
    format.

    The new per-registry option
    {option}`services.podman.settings.registries.registry` was added. Use
    entries like `{ location = "registry.example"; insecure = true; }` or
    `{ location = "registry.example"; blocked = true; }`.

    Legacy {option}`services.podman.settings.registries.insecure` and
    {option}`services.podman.settings.registries.block` are still supported
    but deprecated, and now emit a warning.
  '';
}
