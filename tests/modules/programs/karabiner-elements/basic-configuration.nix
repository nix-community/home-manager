_:

{
  programs.karabiner-elements = {
    enable = true;
    settings = {

    };
  };

  nmt.script = ''
    config_file=$TESTED/home-files/.config/karabiner/karabiner.json
    assertFileExists $config_file
  '';
}
