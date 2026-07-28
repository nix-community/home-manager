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
        echo 'self.exe_path = which(self.program_name)' > radioactive/mpv.py

        runHook postPatch

        cp radioactive/mpv.py "$out/share/radio-active/mpv.py"
        touch "$out/bin/radio-active-custom"
      '';
      extraAttrs.postPatch = "echo previous";
    };

    settings.AppConfig.player = "mpv";
  };

  nmt.script = ''
    assertFileExists home-path/bin/radio-active-custom
    assertFileContent home-path/share/radio-active/mpv.py \
    ${builtins.toFile "expected.radio-active_mpv.py" ''
      self.exe_path = "${lib.getExe pkgs.mpv}"
    ''}

    assertFileExists home-files/.config/radio-active/configs.ini
    assertFileContent home-files/.config/radio-active/configs.ini \
    ${builtins.toFile "expected.player_mpv.radio-active_configs.ini" ''
      [AppConfig]
      player=mpv
    ''}
  '';
}
