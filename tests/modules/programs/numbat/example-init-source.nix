{
  config,
  pkgs,
  ...
}:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/numbat"
    else
      ".config/numbat";
in
{
  programs.numbat = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    initFile.source = builtins.toFile "init.nbt" ''
      unit kohm: ElectricResistance = kV/A
    '';
  };

  nmt.script = ''
    assertFileExists 'home-files/${configDir}/init.nbt'
    assertFileContent $(normalizeStorePaths 'home-files/${configDir}/init.nbt') \
      ${builtins.toFile "expected.nbt" ''
        unit kohm: ElectricResistance = kV/A
      ''}
  '';
}
