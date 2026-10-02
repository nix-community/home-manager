{
  config,
  ...
}:
{
  programs.github-copilot-cli = {
    enable = true;
    mutableSettings = true;
    settings = {
      model = "claude-sonnet-4-5";
      theme = "dark";
      # Copilot CLI keeps trusted folders in its own state, so both spellings
      # are left out of the file.
      trusted_folders = [ "/home/user/projects" ];
      trustedFolders = [ "/home/user/projects" ];
    };
  };

  test.asserts.warnings.expected = [
    ''
      programs.github-copilot-cli.settings: trusted_folders and trustedFolders
      are not written to settings.json. Copilot CLI keeps trusted folders in
      its own state; use programs.github-copilot-cli.trustedFolders instead.
    ''
  ];

  # The merge itself is covered by the mkImpureConfigMerger tests; this checks
  # what the module passes to it.
  nmt.script =
    assert config.home.activation.githubCopilotCliSettings.after == [ "linkGeneration" ];
    assert !(config.home.activation ? githubCopilotCliImmutableSettings);
    ''
      assertPathNotExists home-files/.copilot/config.json
      assertPathNotExists home-files/.copilot/settings.json
      assertFileContains activate 'Merging Nix-generated config into /home/hm-user/.copilot/settings.json'
      assertFileRegex activate '/bin/pyjson5 --as-json'
      generated="$(grep -o '/nix/store/[^ ]*-github-copilot-cli-settings.json' "$TESTED/activate" | head -n1)"
      assertFileContent "$generated" ${./expected-config.json}
    '';
}
