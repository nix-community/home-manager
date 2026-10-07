{
  programs.antigravity-cli = {
    enable = true;
    package = null;
    useLegacyGeminiConfig = true;
    permissions = {
      allow = [ "command(git)" ];
    };
  };
  nmt.script = ''
    assertFileContent home-files/.gemini/settings.json ${./permissions-legacy-partial.json}
  '';
}
