{
  imports = [ ./opencode-stubs.nix ];

  programs.opencode = {
    enable = true;
    settings = {
      model = "anthropic/claude-sonnet-4-5";
      autoshare = false;
      autoupdate = true;
    };
    validateFiles.config = true;
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/opencode.json
    assertFileContent home-files/.config/opencode/opencode.json \
      ${./opencode.json}
  '';
}
