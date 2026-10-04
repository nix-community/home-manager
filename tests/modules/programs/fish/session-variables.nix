{ config, realPkgs, ... }:

{
  config = {
    home.sessionVariables = {
      V1 = "v1";
      V2 = "v2-${config.home.sessionVariables.V1}";
    };

    # Arithmetic expansion does not survive babelfish, which the extra section
    # still goes through, so count with string append instead.
    home.sessionVariablesExtra = ''
      EXTRA_RUNS="''${EXTRA_RUNS-}x"
      export EXTRA_RUNS
    '';

    programs.fish.enable = true;

    nmt.script = ''
      sessionVars=home-path/etc/profile.d/hm-session-vars.fish
      assertFileExists $sessionVars

      # Fish is the shell most likely to diverge, because it gets a separate
      # generator rather than a translation of the POSIX file. Assert the same
      # behaviour that file is checked for, rather than pinning its text.
      env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
        ${realPkgs.fish}/bin/fish --no-config -c '
          set -gx V1 stale
          set -gx V2 stale

          source $argv[1]
          test "$V1" = v1; or begin; echo "V1: $V1"; exit 1; end
          test "$V2" = v2-v1; or begin; echo "V2: $V2"; exit 1; end
          test "$EXTRA_RUNS" = x
          or begin; echo "EXTRA_RUNS: $EXTRA_RUNS"; exit 1; end

          # Applying it again converges and does not re-run the extra section.
          source $argv[1]
          test "$V1" = v1; or begin; echo "V1 after re-source: $V1"; exit 1; end
          test "$EXTRA_RUNS" = x
          or begin; echo "extra ran again: $EXTRA_RUNS"; exit 1; end
          exit 0
        ' "$TESTED/$sessionVars" \
        || fail "fish did not refresh session variables"
    '';
  };
}
