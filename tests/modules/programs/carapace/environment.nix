{ pkgs, ... }:

{
  programs.carapace = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
    package =
      pkgs.writeShellScriptBin "carapace" ''
        printf '%s\n' "$CARAPACE_BRIDGES" "$CARAPACE_HIDDEN" "$CARAPACE_LENIENT" "$CARAPACE_MATCH"
      ''
      // {
        meta.mainProgram = "carapace";
      };
    environment = {
      bridges = "inshellisense,fish";
      hidden = 2;
      lenient = false;
      match = true;
    };
  };

  nmt.script = ''
    "$TESTED/home-path/bin/carapace" > "$TMPDIR/environment.actual"
    assertFileContent "$TMPDIR/environment.actual" ${pkgs.writeText "environment.expected" ''
      inshellisense,fish
      2
      0
      1
    ''}
  '';
}
