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
    settings = {
      intro-banner = "short";
      prompt = "> ";
      exchange-rates.fetching-policy = "on-first-use";
    };
    initFile = ''
      unit kohm: ElectricResistance = kV/A
    '';
  };

  nmt.script = ''
    assertFileExists 'home-files/${configDir}/config.toml'
    assertFileContent $(normalizeStorePaths 'home-files/${configDir}/config.toml') \
      ${builtins.toFile "expected.toml" ''
        intro-banner = "short"
        prompt = "> "

        [exchange-rates]
        fetching-policy = "on-first-use"
      ''}
    assertFileExists 'home-files/${configDir}/init.nbt'
    assertFileContent $(normalizeStorePaths 'home-files/${configDir}/init.nbt') \
      ${builtins.toFile "expected-init.nbt" ''
        unit kohm: ElectricResistance = kV/A
      ''}
  '';
}
