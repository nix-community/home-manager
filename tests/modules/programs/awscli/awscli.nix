{ ... }:

{
  programs = {
    awscli = {
      enable = true;
      settings = {
        default = {
          output = "json";
          region = "eu-west-3";
        };
      };
      credentials = { iam = { credential_process = "pass show aws"; }; };
    };
  };

  test.stubs.awscli2 = { };

  nmt.script = ''
    assertFileExists home-files/.aws/config
    assertFileContent home-files/.aws/config \
      ${./aws-config.conf}

    assertFileExists home-files/.aws/credentials
    assertFileContent home-files/.aws/credentials \
      ${./aws-credentials.conf}
  '';
}
