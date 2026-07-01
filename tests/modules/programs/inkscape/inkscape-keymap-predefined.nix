{
  programs.inkscape = {
    enable = true;
    keymapSet = "illustrator";
  };

  nmt.script = ''
    keysFile=home-files/.config/inkscape/keys/default.xml

    assertFileExists "$keysFile"
    assertFileContains "$keysFile" 'illustrator'
    assertFileContains "$keysFile" 'xi:include'
  '';
}
