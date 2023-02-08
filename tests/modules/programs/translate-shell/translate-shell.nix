{ ... }:

{
  programs.translate-shell = {
    enable = true;
    settings = {
      verbose = true;
      engine = "bing";
      play = true;
      hl = "en";
      tl = [ "de" "fr" ];
    };
  };

  test.stubs.translate-shell = { };

  nmt.script = ''
    assertFileContent home-files/.config/translate-shell/init.trans \
    ${builtins.toFile "translate-shell-expected-settings.trans" ''
      {:engine "bing"
      :hl "en"
      :play true
      :tl [ "de" "fr" ]
      :verbose true
      }''}
  '';
}
