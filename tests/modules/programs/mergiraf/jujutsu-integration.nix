{
  programs.jujutsu = {
    enable = true;
    package = null;
  };
  programs.mergiraf = {
    enable = true;
    enableJujutsuIntegration = true;
    # Do not warn about default value
    enableGitIntegration = false;
  };

  nmt.script = ''
    assertFileExists 'home-files/.config/jj/config.toml'
    assertFileContent 'home-files/.config/jj/config.toml' \
      ${builtins.toFile "expected.toml" ''
        [merge-tools.mergiraf]
        program = "@mergiraf@/bin/mergiraf"

        [ui]
        merge-editor = "mergiraf"
      ''}
  '';
}
