{
  config,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = null;
    mutableSettings = true;
    configDir = "${config.home.homeDirectory}/custom-claude";
    settings = {
      theme = "dark";
      permissions = {
        allow = [ "Read" ];
        ask = [ ];
      };
    };
    marketplaces = {
      existing = pkgs.emptyDirectory;
      new = pkgs.emptyDirectory;
    };
  };
  assertions = [
    {
      assertion = (config.home.activation.claudeCodeSettings.after or [ ]) == [ "linkGeneration" ];
      message = "Mutable Claude Code settings must activate after linkGeneration.";
    }
  ];

  nmt.script = ''
    assertPathNotExists home-files/custom-claude/settings.json
    assertPathNotExists home-files/custom-claude/plugins/known_marketplaces.json
    assertFileContains activate '${config.programs.claude-code.configDir}/settings.json'
    assertFileContains activate '${config.programs.claude-code.configDir}/plugins/known_marketplaces.json'

    settings="$(grep -o '/nix/store/[^ ]*-claude-code-settings.json' "$TESTED/activate")" \
      || fail "Claude Code settings input is missing from activation"
    marketplaces="$(grep -o '/nix/store/[^ ]*-claude-code-known-marketplaces.json' "$TESTED/activate")" \
      || fail "Claude Code marketplaces input is missing from activation"
    substitute ${./mutable-settings-expected.json} "$TMPDIR/settings-expected.json" \
      --replace-fail '@marketplace@' '${pkgs.emptyDirectory}'
    substitute ${./mutable-marketplaces-expected.json} "$TMPDIR/marketplaces-expected.json" \
      --replace-fail '@marketplace@' '${pkgs.emptyDirectory}'
    assertFileContent "$settings" "$TMPDIR/settings-expected.json"
    assertFileContent "$marketplaces" "$TMPDIR/marketplaces-expected.json"
    marketplaceFilter="$(${pkgs.gnused}/bin/sed -n '/reduce (\$static | keys\[\]) as \$name/,+1p' "$TESTED/activate")"
    [[ -n "$marketplaceFilter" ]] || fail "Claude Code marketplace filter is missing from activation"
    substitute ${./merge-marketplaces-expected.json} "$TMPDIR/merged-expected.json" \
      --replace-fail '@marketplace@' '${pkgs.emptyDirectory}'
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat ${./merge-marketplaces-saved.json})" --argjson static "$(cat "$marketplaces")" "$marketplaceFilter" > merged.json \
      || fail "Claude Code marketplace filter failed"
    assertFileContent "$PWD/merged.json" "$TMPDIR/merged-expected.json"
    ${pkgs.jaq}/bin/jaq -nS --argjson dynamic "$(cat merged.json)" --argjson static "$(cat "$marketplaces")" "$marketplaceFilter" > repeated.json \
      || fail "Repeated Claude Code marketplace filter failed"
    assertFileContent "$PWD/repeated.json" "$TMPDIR/merged-expected.json"
  '';
}
