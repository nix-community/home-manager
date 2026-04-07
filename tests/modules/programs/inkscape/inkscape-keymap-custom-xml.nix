{
  programs.inkscape = {
    enable = true;
    keymapXml = ''
      <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
      <keys name="default">
        <bind key="F2" action="node-tool" display="true"/>
        <bind key="F1" action="select-tool" display="true"/>
      </keys>
    '';
  };

  nmt.script = ''
    keysFile=home-files/.config/inkscape/keys/default.xml

    assertFileExists "$keysFile"
    assertFileContains "$keysFile" 'action="node-tool"'
    assertFileContains "$keysFile" 'action="select-tool"'
  '';
}
