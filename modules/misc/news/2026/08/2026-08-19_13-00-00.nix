{
  time = "2026-08-19T13:00:00+00:00";
  condition = true;
  message = ''
    Generated YAML files now start with a `%YAML 1.1` directive and a
    `---` document start marker.

    Nixpkgs changed `pkgs.formats.yaml` to use remarshal v2, which emits
    this header. Every Home Manager module that writes YAML through that
    format is affected.

    Most YAML parsers accept the header. If a program rejects it, report
    the problem to that program and write the file through
    `home.file` or `xdg.configFile` with explicit text instead.
  '';
}
