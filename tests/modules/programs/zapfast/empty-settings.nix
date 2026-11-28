{
  config,
  ...
}:
{
  programs.zapfast = {
    enable = true;
    package = null;
  };

  nmt.script =
    assert !(config.home.activation ? zapfastSettings);
    ''
      assertPathNotExists home-files/.config/zapfast/settings.json
      assertPathNotExists "home-files/Library/Application Support/me.paolino.zapfast/settings.json"
      assertFileNotRegex activate 'zapfast/settings\.json|me\.paolino\.zapfast/settings\.json'
    '';
}
