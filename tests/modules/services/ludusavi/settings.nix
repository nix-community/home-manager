{
  services.ludusavi = {
    enable = true;
    settings = {
      language = "en-US";
      theme = "light";
      roots = [
        {
          path = "~/.local/share/Steam";
          store = "steam";
        }
      ];
      backup.path = "~/.local/state/backups/ludusavi";
      restore.path = "~/.local/state/backups/ludusavi";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ludusavi/config.yaml
    assertFileContent home-files/.config/ludusavi/config.yaml \
      ${./config.yaml}
  '';
}
