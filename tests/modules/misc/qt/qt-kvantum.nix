{ pkgs, ... }:

{
  qt = {
    enable = true;
    kvantum.theme.name = "KvAdapta";
  };

  nmt.script =
    let
      configPath = "home-files/.config/Kvantum/kvantum.kvconfig";

      expectedContent = pkgs.writeText "expected.kvconfig" ''
        [General]
        theme=KvAdapta
      '';
    in
    ''
      assertFileExists "${configPath}"
      assertFileContent "${configPath}" "${expectedContent}"
    '';
}
