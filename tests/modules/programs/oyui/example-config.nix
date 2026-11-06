let
  config = ''
    pub fn config() {
      keybind("c", global::confirm);
    }
  '';
in
{
  programs.oyui = {
    enable = true;
    package = null;
    inherit config;
  };

  nmt.script = ''
    assertFileExists home-files/.config/oyui/config.rn
    assertFileContent home-files/.config/oyui/config.rn \
      ${builtins.toFile "expected-config.rn" config}
  '';
}
