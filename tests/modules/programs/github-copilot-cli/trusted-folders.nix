{ config, ... }:
{
  programs.github-copilot-cli = {
    enable = true;
    settings.trusted_folders = [ "/home/user/projects" ];
  };

  test.asserts.warnings.expected = [
    ''
      programs.github-copilot-cli.settings: trusted_folders and trustedFolders
      are not written to settings.json. Copilot CLI keeps trusted folders in
      its own state; trust folders from Copilot CLI instead.
    ''
  ];

  nmt.script =
    assert !(config.home.activation ? githubCopilotCliSettings);
    ''
      assertPathNotExists home-files/.copilot/settings.json
      assertPathNotExists home-files/.copilot/config.json
    '';
}
