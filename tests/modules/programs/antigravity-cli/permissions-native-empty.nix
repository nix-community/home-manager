{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    permissions = { };
  };
  nmt.script = ''
    assertFileContent home-files/.gemini/antigravity-cli/settings.json ${./permissions-native-empty.json}
  '';
}
