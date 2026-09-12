{ pkgs, ... }:
{
  home.enableNixpkgsReleaseCheck = false;

  test.stubs.neverest = { };

  programs.neverest = {
    enable = true;
  };

  accounts.email = {
    maildirBasePath = "mail";
    accounts = {
      "example" = {
        primary = true;
        address = "user@example.com";
        userName = "user@example.com";
        passwordCommand = "hiq -dF password proto=imaps host=imap.example.com";
        maildir.path = "example";
        imap = {
          host = "imap.example.com";
          port = 993;
          tls.enable = true;
        };

        neverest = {
          enable = true;
          poolSize = 3;
        };
      };

      "work" = {
        address = "work@work.com";
        userName = "work@work.com";
        passwordCommand = "pass show email/work";
        maildir.path = "work";
        imap = {
          host = "imap.work.com";
          port = 993;
          tls.enable = true;
        };

        neverest = {
          enable = true;
          extraConfig = {
            right.backend.watch.timeout = 1800;
          };
        };
      };

      # An account with neverest disabled to double-check filtering
      "ignored" = {
        address = "ignored@domain.com";
        maildir.path = "ignored";
        neverest.enable = false;
      };
    };
  };

  nmt.script =
    let
      configFile =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "home-files/Library/Application Support/neverest/config.toml"
        else
          "home-files/.config/neverest/config.toml";
    in
    ''
      assertFileExists "${configFile}"
      assertFileContent "${configFile}" ${./neverest-expected.toml}
    '';
}
