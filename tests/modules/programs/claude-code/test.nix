{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      claude-code = pkgs.writeShellScriptBin "claude" ''
        echo "Claude Code CLI mock"
      '';
    })
  ];

  programs.claude-code = { enable = true; };

  nmt.script = ''
    assertFileRegex activate "claude config set -g autoUpdaterStatus disabled"
  '';
}
