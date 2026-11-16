{ pkgs, ... }:
{
  programs.algia = {
    enable = true;
    package = null;
    mutableSettings = true;
    settings.followList = [ "declared" ];
  };

  nmt.script = ''
    filter="$(${pkgs.gnused}/bin/sed -n '/^ *([$]dynamic \* [$]static)$/,+5p' "$TESTED/activate")"
    [[ -n "$filter" ]] || fail "Algia follow list filter is missing from activation"
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved.json})" --argjson static "$(cat ${./merge-declared.json})" "$filter" > union.json \
      || fail "Algia union filter command failed"
    assertFileContent "$PWD/union.json" ${./merge-expected.json}
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved.json})" --argjson static "$(cat ${./merge-null.json})" "$filter" > null.json \
      || fail "Algia null filter command failed"
    assertFileContent "$PWD/null.json" ${./merge-null-expected.json}
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved.json})" --argjson static "$(cat ${./merge-empty.json})" "$filter" > empty.json \
      || fail "Algia empty filter command failed"
    assertFileContent "$PWD/empty.json" ${./merge-empty-expected.json}
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved.json})" --argjson static "$(cat ${./merge-absent.json})" "$filter" > absent.json \
      || fail "Algia absent filter command failed"
    assertFileContent "$PWD/absent.json" ${./merge-absent-expected.json}
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved-null.json})" --argjson static "$(cat ${./merge-declared.json})" "$filter" > saved-null.json \
      || fail "Algia saved-null filter command failed"
    assertFileContent "$PWD/saved-null.json" ${./merge-new-expected.json}
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-saved-absent.json})" --argjson static "$(cat ${./merge-declared.json})" "$filter" > saved-absent.json \
      || fail "Algia saved-absent filter command failed"
    assertFileContent "$PWD/saved-absent.json" ${./merge-new-expected.json}
  '';
}
