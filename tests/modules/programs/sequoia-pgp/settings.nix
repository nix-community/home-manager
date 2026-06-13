{
  config,
  pkgs,
  ...
}:
{
  programs.sequoia-pgp = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "sequoia-sq";
      outPath = "@sequoia-sq@";
    };

    settings = {
      ui = {
        hints = false;
        verbosity = "quiet";
      };

      encrypt.for-self = [ "EB28F26E2739A4870ECC47726F0073F60FD0CBF0" ];

      network = {
        keyservers = [ "hkps://keys.openpgp.org" ];
        search.iterations = 3;
      };

      policy = {
        path = "/etc/crypto-policies/back-ends/sequoia.config";
        hash_algorithms = {
          sha1 = "never";
          ignore_invalid = [ "sha4" ];
        };
        packets."signature.v5" = "never";
      };
    };

    extraConfig = ''
      [policy.asymmetric_algorithms]
      rsa1024 = 2014-02-01
    '';
  };

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/org.Sequoia-PGP.sequoia/sq/config.toml"
        else
          "home-files/.config/sequoia/sq/config.toml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileRegex "${configFile}" "verbosity = 'quiet'"
      assertFileRegex "${configFile}" "keyservers = \\['hkps://keys.openpgp.org'\\]"
      assertFileRegex "${configFile}" "path = '/etc/crypto-policies/back-ends/sequoia.config'"
      assertFileRegex "${configFile}" "sha1 = 'never'"
      assertFileRegex "${configFile}" "'signature.v5' = 'never'"
      assertFileRegex "${configFile}" "rsa1024 = 2014-02-01"
    '';
}
