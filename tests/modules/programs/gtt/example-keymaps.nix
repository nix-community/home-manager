{
  programs.gtt = {
    enable = true;

    keymaps = {
      clear = "C-q";
      copy_destination = "C-r";
      copy_selected = "C-y";
      copy_source = "C-g";
      exit = "C-c";
      stop_tts = "C-x";
      swap_language = "C-s";
      toggle_below = "C-\\";
      toggle_transparent = "C-t";
      translate = "C-j";
      tts_destination = "C-p";
      tts_source = "C-o";
    };
  };

  test.stubs.gtt.name = "gtt";

  nmt.script =
    let
      configFile = "home-files/.config/gtt/keymap.yaml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./expected-keymaps.yaml}
    '';
}
