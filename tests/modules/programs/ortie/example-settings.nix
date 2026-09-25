{ config, ... }:
{
  programs.ortie = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    settings = {
      accounts.personal = {
        default = true;
        client-id = "1234-abcd.apps.googleusercontent.com";
        client-secret.command = "pass show ortie/personal-client-secret";
        grant = "authorization-code";
        endpoints.authorization = "https://accounts.google.com/o/oauth2/v2/auth";
        endpoints.token = "https://oauth2.googleapis.com/token";
        scopes = [ "https://mail.google.com/" ];
        pkce = "s256";
        extras.access_type = "offline";
        auto-refresh = true;
        storage.read.command = [
          "pass"
          "show"
          "ortie/personal"
        ];
        storage.write.command = "pass insert -m -f ortie/personal";
        hooks.on-refresh.success.command = "logger 'ortie refreshed a token'";
      };

      accounts.work = {
        grant = "client-credentials";
        client-id = "00000000-0000-0000-0000-000000000000";
        client-secret.command = [
          "secret-tool"
          "lookup"
          "oauth"
          "work"
        ];
        endpoints.token = "https://login.microsoftonline.com/tenant/oauth2/v2.0/token";
        scopes = [ "https://graph.microsoft.com/.default" ];
        storage.read.command = [
          "secret-tool"
          "lookup"
          "token"
          "work"
        ];
        storage.write.command = "secret-tool store --label ortie token work";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ortie/config.toml
    assertFileContent home-files/.config/ortie/config.toml ${./example-settings-expected.toml}
  '';
}
