{ pkgs, ... }:
{
  config = {
    services.pizauth = {
      enable = true;
      extraConfig = ''
        refresh_at_least = 15s;
      '';
      accounts = {
        test1 = {
          authUri = "authUri1";
          tokenUri = "tokenUri1";
          clientId = "clientId1";
          clientSecret = "clientSecret1";
          loginHint = "testLogin1";
          extraConfig = ''
            redirectUri = "redirectUri1";
            refresh_retry = 30s;
          '';
        };
        test2 = {
          authUri = "authUri2";
          tokenUri = "tokenUri2";
          clientId = "clientId2";
          clientSecret = "clientSecret2";
          scopes = [
            "scope1"
            "offline_access"
          ];
        };
      };
    };

    test.stubs.pizauth = { };

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/pizauth.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/dummy server -vvvv -d'

      assertFileExists home-files/.config/pizauth.conf
      assertFileContent home-files/.config/pizauth.conf \
        ${pkgs.writeText "expected-config" ''
          refresh_at_least = 15s;

          account "test1" {
            auth_uri = "authUri1";
            token_uri = "tokenUri1";
            client_id = "clientId1";
            client_secret = "clientSecret1";
            login_hint = "testLogin1";
            redirectUri = "redirectUri1";
            refresh_retry = 30s;
          }

          account "test2" {
            auth_uri = "authUri2";
            token_uri = "tokenUri2";
            client_id = "clientId2";
            client_secret = "clientSecret2";
            scopes = [
              "scope1",
              "offline_access"
            ];
          }
        ''}
    '';
  };
}
