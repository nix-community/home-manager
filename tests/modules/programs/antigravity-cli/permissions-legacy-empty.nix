{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    useLegacyGeminiConfig = true;
    permissions = { };
  };
  nmt.script = ''
    assertFileContent home-files/.gemini/settings.json ${./permissions-legacy-empty.json}
  '';
}
