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
  '';
}
