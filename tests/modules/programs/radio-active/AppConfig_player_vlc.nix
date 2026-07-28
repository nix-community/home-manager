{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.radio-active = {
    enable = true;

    package = config.lib.test.mkStubPackage {
      name = "radio-active-custom";
      buildScript = ''
        mkdir -p radioactive "$out/bin" "$out/share/radio-active"
        echo 'self.exe_path = which(self.program_name)' > radioactive/vlc.py

        runHook postPatch

        cp radioactive/vlc.py "$out/share/radio-active/vlc.py"
        touch "$out/bin/radio-active-custom"
      '';
      extraAttrs.postPatch = null;
    };

    settings.AppConfig.player = "vlc";
  };

  nmt.script = ''
    assertFileExists home-path/bin/radio-active-custom
    assertFileContent home-path/share/radio-active/vlc.py \
    ${builtins.toFile "expected.radio-active_vlc.py" ''
      self.exe_path = "${lib.getExe pkgs.vlc}"
    ''}

    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.player_vlc.radio-active_configs.ini" ''
      [AppConfig]
      player=vlc
    ''}
  '';
}
