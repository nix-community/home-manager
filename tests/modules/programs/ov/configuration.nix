{
  programs.ov = {
    enable = true;
    settings = {
      KeyBind = {
        half_page_down = [ "d" ];
        half_page_up = [ "u" ];
      };
      Prompt = {
        Normal = {
          Prefix = " ";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ov/config.yaml
    assertFileContent home-files/.config/ov/config.yaml \
      ${./expected-config.yaml}
  '';
}
