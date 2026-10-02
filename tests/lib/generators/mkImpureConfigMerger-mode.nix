{ lib, pkgs, ... }:

let
  mkMerger =
    options:
    lib.hm.generators.mkImpureConfigMerger (
      {
        inherit pkgs;
        format = "json";
        empty = "{}";
        jqOperation = "$dynamic * $static";
        path = "/@TMPDIR@/merger-mode/settings.json";
        staticSettings = builtins.toFile "settings.json" ''{"managed":true}'';
      }
      // options
    );
  mkScript =
    name: options:
    pkgs.writeScript name ''
      set -euo pipefail
      errorEcho() { echo "$*" >&2; }
      ${mkMerger options}
    '';
  defaultMode = mkScript "merge-default-mode" { };
  privateMode = mkScript "merge-private-mode" { mode = "600"; };
  # An integer such as 600 must fail the same assertion, not a type error.
  invalidModeRejected =
    lib.all
      (
        mode:
        !(builtins.tryEval (mkMerger {
          inherit mode;
        })).success
      )
      [
        "u=rw"
        600
      ];
in
{
  nmt.script = ''
    substitute ${defaultMode} "$TMPDIR/default-mode" --subst-var TMPDIR
    substitute ${privateMode} "$TMPDIR/private-mode" --subst-var TMPDIR
    chmod +x "$TMPDIR/default-mode" "$TMPDIR/private-mode"
    settings="$TMPDIR/merger-mode/settings.json"

    (umask 022 && "$TMPDIR/default-mode")
    [[ "$(stat -c '%a' "$settings")" == 644 ]] || fail "Expected umask mode 644"
    rm "$settings"
    (umask 077 && "$TMPDIR/default-mode")
    [[ "$(stat -c '%a' "$settings")" == 600 ]] || fail "Expected umask mode 600"
    rm "$settings"
    "$TMPDIR/private-mode"
    [[ "$(stat -c '%a' "$settings")" == 600 ]] || fail "Expected configured mode 600"

    chmod 640 "$settings"
    "$TMPDIR/private-mode"
    [[ "$(stat -c '%a' "$settings")" == 640 ]] || fail "Existing mode must be preserved"
    ${lib.getExe pkgs.jaq} -e '.managed == true' "$settings" > /dev/null

    ${lib.optionalString (!invalidModeRejected) ''
      fail "A non-octal mode must be rejected during evaluation"
    ''}
  '';
}
