{
  programs.uv = {
    enable = true;
    tool = {
      packages = [
        "ruff"
        "black==24.1.0"
      ];
      prune = true;
    };
  };

  test.stubs.uv.name = "uv";

  nmt.script = ''
    # With prune the set is fully declarative, but only the diff is touched: the
    # installed tools are read from uv's tool directory (entries are already
    # PEP 503-normalized package names) and diffed against the requested names
    # (extras and version specifiers dropped and normalized at build time), so
    # only tools that are no longer requested are uninstalled, one by one.
    assertFileContains activate \
      'uvToolDir=$(@uv@/bin/uv tool dir)'
    assertFileContains activate \
      'ls -1 "$uvToolDir" | sort -u'
    assertFileContains activate \
      "comm -23 - <(printf '%s\n' ruff black | sort -u)"
    assertFileContains activate \
      'run @uv@/bin/uv tool uninstall $VERBOSE_ARG "$uvTool"'

    # Name normalization happens in Nix now; no shell helper or output parsing.
    assertFileNotRegex activate 'uvNorm'
    assertFileNotRegex activate 'uv tool list'

    # The old brute-force `uninstall --all` reinstall churn is gone; kept tools
    # are only installed/upgraded, never uninstalled and reinstalled.
    assertFileNotRegex activate 'tool uninstall \$VERBOSE_ARG --all'

    assertFileContains activate \
      'run @uv@/bin/uv tool install $VERBOSE_ARG ruff'
    assertFileContains activate \
      "run @uv@/bin/uv tool install \$VERBOSE_ARG 'black==24.1.0'"
    assertFileContains activate \
      "run @uv@/bin/uv tool upgrade \$VERBOSE_ARG ruff 'black==24.1.0'"
  '';
}
