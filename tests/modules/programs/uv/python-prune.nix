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
    # With prune the set is fully declarative, but only the diff is touched:
    # each requested version is resolved to the key uv would install (matching is
    # delegated to uv, `--managed-python` keeps system Pythons out of reach). We
    # keep the install target (`.[0]`, newest match), not every installed match,
    # so superseded patch releases uv retains on upgrade are still pruned.
    assertFileContains activate \
      'for uvReq in 3.12 3.13; do'
    assertFileContains activate \
      '@uv@/bin/uv python list "$uvReq" --managed-python --output-format json'
    assertFileContains activate \
      "done | jq -s 'map(.[0].key // empty)'"
    # …then managed installs outside that target set are uninstalled, one by one,
    # via a set difference (jq's `-` operator) against the kept keys.
    assertFileContains activate \
      '@uv@/bin/uv python list --only-installed --managed-python --output-format json'
    assertFileContains activate \
      "jq -r --argjson keep \"\$uvKeep\" '([.[].key] | unique) - \$keep | .[]'"
    assertFileContains activate \
      'run @uv@/bin/uv python uninstall $VERBOSE_ARG "$uvKey"'

    # The old brute-force `uninstall --all` reinstall churn is gone; kept
    # versions are only installed/upgraded, never uninstalled and reinstalled.
    assertFileNotRegex activate 'python uninstall \$VERBOSE_ARG --all'

    # A bare string for `default` is coerced to a single-element list, installed
    # with `--default`. Both requests are major/minor, so they install with
    # `--upgrade`.
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --default --upgrade 3.13'
    assertFileContains activate \
      'run @uv@/bin/uv python install $VERBOSE_ARG --upgrade 3.12'
  '';
}
