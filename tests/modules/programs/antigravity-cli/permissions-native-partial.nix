{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    permissions = {
      allow = [ "command(git)" ];
    };
  };
  nmt.script = ''
    assertFileContent home-files/.gemini/antigravity-cli/settings.json ${./permissions-native-partial.json}
  '';
}
