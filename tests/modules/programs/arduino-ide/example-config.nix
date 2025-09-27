{
  programs.arduino-ide = {
    enable = true;
    cliSettings = {
      board_manager = {
        enable_unsafe_install = true;
        additional_urls = [
          "https://downloads.arduino.cc/packages/package_staging_index.json"
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.arduinoIDE/arduino-cli.yaml
    assertFileContent home-files/.arduinoIDE/arduino-cli.yaml \
    ${./arduino-cli.yaml}
  '';
}
