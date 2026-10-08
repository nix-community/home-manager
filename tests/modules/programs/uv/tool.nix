{
  programs.uv = {
    enable = true;
    tool.packages = [
      "ruff"
      "black==24.1.0"
      "poetry[plugin]"
    ];
  };

  test.stubs.uv.name = "uv";

  nmt.script = ''
    # Each tool is installed individually, preserving extras and specifiers.
    assertFileContains activate \
      'run @uv@/bin/uv tool install $VERBOSE_ARG ruff'
    assertFileContains activate \
      "run @uv@/bin/uv tool install \$VERBOSE_ARG 'black==24.1.0'"
    assertFileContains activate \
      "run @uv@/bin/uv tool install \$VERBOSE_ARG 'poetry[plugin]'"

    # Upgrading is delegated to uv but scoped to the configured tools, so tools
    # installed outside this option are untouched; per-tool constraints hold.
    assertFileContains activate \
      "run @uv@/bin/uv tool upgrade \$VERBOSE_ARG ruff 'black==24.1.0' 'poetry[plugin]'"

    # Without prune the performant path is used: no uninstall/reinstall churn.
    assertFileNotRegex activate 'tool uninstall'
  '';
}
