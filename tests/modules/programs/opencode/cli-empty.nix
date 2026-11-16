{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    cli = { };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/opencode/cli.json
  '';
}
