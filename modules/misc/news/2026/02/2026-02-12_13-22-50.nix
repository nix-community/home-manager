{ config, ... }:
{
  time = "2026-02-12T19:22:50+00:00";
  condition = config.programs.pay-respects.enable;
  message = ''
    The option `programs.pay-respects.rules` was added.

    It generates runtime rule files at
    {file}`$XDG_CONFIG_HOME/pay-respects/rules/<name>.toml`, where each
    attribute name under `rules` becomes a filename (for example, `rules.cargo`
    writes `cargo.toml`).

    For the full runtime-rules format and command matching requirements, see
    <https://github.com/iffse/pay-respects/blob/main/rules.md>.
  '';
}
