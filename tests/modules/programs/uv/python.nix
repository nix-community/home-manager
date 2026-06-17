{
  programs.uv = {
    enable = true;
    python = {
      versions = [
        "3.12"
        "3.13"
        "3.11.9"
        "pypy@3.11"
      ];
      # One default per implementation; uv keeps `python` and `pypy` separate.
      default = [
        "3.13"
        "pypy@3.11"
      ];
    };
  };

  test.stubs.uv.name = "uv";

  nmt.script = ''
    # Each default is installed first with `--default`, one call per entry, so
    # per-implementation executables (python, pypy) are both set. They have no
    # patch component, so they also track the latest patch via `--upgrade`.
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --default --upgrade 3.13'
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --default --upgrade pypy@3.11'

    # Remaining major/minor requests are installed with `--upgrade`, tracking the
    # latest patch; default versions are not reinstalled.
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --upgrade 3.12'

    # Exact-patch pins are installed as requested, never upgraded (uv rejects
    # upgrading them).
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG 3.11.9'

    # Without prune the performant path is used: no uninstall/reinstall churn.
    assertFileNotRegex activate 'python uninstall'
  '';
}
