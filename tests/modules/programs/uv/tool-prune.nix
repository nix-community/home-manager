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
    # With prune, all tools are removed before (re)installing the listed ones,
    # making the set fully declarative.
    assertFileContains activate \
      'run @uv@/bin/uv tool uninstall $VERBOSE_ARG --all'
    assertFileContains activate \
      'run @uv@/bin/uv tool install $VERBOSE_ARG ruff'
    assertFileContains activate \
      "run @uv@/bin/uv tool install \$VERBOSE_ARG 'black==24.1.0'"
    assertFileContains activate \
      "run @uv@/bin/uv tool upgrade \$VERBOSE_ARG ruff 'black==24.1.0'"
  '';
}
