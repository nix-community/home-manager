{
  services.clipse = {
    enable = true;

    settings = {
      allowDuplicates = true;
      imageDisplay = {
        type = "kitty";
        scaleX = 9;
        scaleY = 9;
      };
    };

    # Legacy option renamed to `services.clipse.settings.maxHistory`.
    historySize = 1001;
  };

  test = {
    stubs.clipse = { };

    asserts.warnings.expected = [
      "The option `services.clipse.historySize' defined in `${toString ./clipse-settings.nix}' has been renamed to `services.clipse.settings.maxHistory'."
    ];
  };

  nmt.script = ''
    configFile=home-files/.config/clipse/config.json
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./clipse-settings-expected.json}
  '';
}
