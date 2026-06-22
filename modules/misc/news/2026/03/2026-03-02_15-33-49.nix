{
  time = "2026-03-02T15:33:49+00:00";
  condition = true;
  message = ''
    New modules are available: 'programs.cursor', 'programs.vscodium',
    'programs.windsurf', 'programs.kiro', and 'programs.antigravity'.

    These provide dedicated configuration for VSCode-based editors,
    allowing multiple editors to be configured simultaneously.

    Users who previously set 'programs.vscode.package' to a non-vscode
    package (e.g. pkgs.vscodium) should migrate to the corresponding
    dedicated module instead.
  '';
}
