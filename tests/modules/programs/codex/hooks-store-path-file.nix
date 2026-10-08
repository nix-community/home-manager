{ realPkgs, ... }:

let
  hooks = realPkgs.runCommand "codex-ifd-hooks-file" { } ''
    echo '{"hooks": {}}' > "$out"
  '';
in
{
  programs.codex = {
    enable = true;
    hooks = "${hooks}";
  };

  nmt.script = ''
    assertFileContent home-files/.codex/hooks.json "${hooks}"
    assertPathNotExists home-files/.codex/hooks
  '';
}
