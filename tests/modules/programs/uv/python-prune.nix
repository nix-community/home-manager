{
  programs.uv = {
    enable = true;
    python = {
      versions = [
        "3.12"
        "3.13"
      ];
      default = "3.13";
      prune = true;
    };
  };

  test.stubs.uv.name = "uv";

  nmt.script = ''
    # With prune, all managed versions are removed before (re)installing the
    # listed ones, making the set fully declarative. A bare string for `default`
    # is coerced to a single-element list, installed with `--default`. Both
    # requests are major/minor, so they install with `--upgrade`.
    assertFileContains activate \
      'run @uv@/bin/uv python uninstall $VERBOSE_ARG --all'
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --default --upgrade 3.13'
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --upgrade 3.12'
  '';
}
