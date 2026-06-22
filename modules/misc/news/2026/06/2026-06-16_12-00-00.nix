{ config, ... }:

{
  time = "2026-06-16T12:00:00+00:00";
  condition = config.programs.uv.enable;
  message = ''
    The 'programs.uv' module can now manage uv-installed Python versions and
    tools declaratively.

    Use {option}`programs.uv.python.versions` to install Python versions
    (with {option}`programs.uv.python.default` selecting the default interpreter
    per implementation) and {option}`programs.uv.tool.packages` to install
    tools. Unpinned entries track the latest release on each activation, while
    pinned ones (e.g. `"3.12.4"` or `"black==24.1.0"`) stay put. Set
    {option}`programs.uv.python.prune` or {option}`programs.uv.tool.prune` to
    make the managed set fully declarative, removing versions and tools that are
    no longer listed.
  '';
}
