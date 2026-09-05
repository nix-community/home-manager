{
  programs = {
    saml2aws = {
      enable = true;
      credentials = {
        aws = {
          name = "aws";
          url = "https://domain.tld/uri/of/your/auth/endpoint";
          username = "username";
          provider = "Authentik";
          mfa = "Auto";
          skip_verify = false;
          timeout = 0;
          aws_urn = "urn:amazon:webservices";
          aws_session_duration = 3600;
          aws_profile = "123456789000";
          saml_cache = false;
          disable_remember_device = false;
          disable_sessions = false;
          download_browser_driver = false;
          headless = false;
        };

      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.saml2aws
    assertFileContent home-files/.saml2aws \
      ${./saml2aws.conf}
  '';
}
