_: {
  programs.opkssh = {
    enable = true;
    settings = {
      default_provider = "test-provider";
      providers = [
        {
          alias = "test-provider";
          issuer = "https://test.domain/oauth2/openid/opkssh";
          client_id = "opkssh";
          scopes = "openid email profile";
          redirect_uris = [
            "http://localhost:3000/login-callback"
            "http://localhost:10001/login-callback"
            "http://localhost:11110/login-callback"
          ];
        }
      ];
    };
  };

  nmt.script = ''
    configFile=home-files/.opk/config.yml

    assertFileExists "$configFile"

    configFileNormalized="$(normalizeStorePaths "$configFile")"

    assertFileContent "$configFileNormalized" ${builtins.toFile "expected.service" ''
      default_provider: test-provider
      providers:
      - alias: test-provider
        client_id: opkssh
        issuer: https://test.domain/oauth2/openid/opkssh
        redirect_uris:
        - http://localhost:3000/login-callback
        - http://localhost:10001/login-callback
        - http://localhost:11110/login-callback
        scopes: openid email profile
    ''}
  '';
}
