{ pkgs, ... }:

{
  qt = {
    enable = true;
    kvantum = {
      settings = {
        general = {
          theme = "KvAdapta";
        };
      };
      themes = [
        (pkgs.runCommand "kvantum-test-theme" { } ''
          mkdir -p $out/share/Kvantum/TestTheme
          touch $out/share/Kvantum/TestTheme/TestTheme.kvconfig
        '')
      ];
    };
  };

  nmt.script =
    let
      configDir = "home-files/.config/Kvantum";
    in
    ''
      assertFileExists "${configDir}/kvantum.kvconfig"
      assertFileExists "${configDir}/TestTheme/TestTheme.kvconfig"
    '';
}
