{
  programs.arduino-cli = {
    enable = true;
    settings = {
      board_manager = {
        enable_unsafe_install = true;
        additional_urls = [
          "https://downloads.arduino.cc/packages/package_staging_index.json"
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.arduino15/arduino-cli.yaml
    assertFileContent home-files/.arduino15/arduino-cli.yaml \
    ${./example-config.yaml}
  '';
}
