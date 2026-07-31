{
  lib,
  options,
  pkgs,
  ...
}:

{
  programs.carapace = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
    package =
      pkgs.writeShellScriptBin "carapace" ''
        printf '%s\n' "$CARAPACE_MATCH"
      ''
      // {
        meta.mainProgram = "carapace";
      };
    ignoreCase = true;
  };

  test.asserts.warnings.expected = [
    "The option `programs.carapace.ignoreCase' defined in ${lib.showFiles options.programs.carapace.ignoreCase.files} has been renamed to `programs.carapace.environment.CARAPACE_MATCH'."
  ];

  nmt.script = ''
    "$TESTED/home-path/bin/carapace" > "$TMPDIR/match.actual"
    assertFileContent "$TMPDIR/match.actual" ${pkgs.writeText "match.expected" ''
      1
    ''}
  '';
}
