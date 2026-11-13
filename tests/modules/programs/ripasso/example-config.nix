{
  programs.ripasso = {
    enable = true;
    settings = {
      stores.default = {
        path = "/home/user/.password-store";
        pgp_implementation = "gpg";
      };
    };
  };

  nmt.script = ''
    assertFileContent "home-files/.config/ripasso/settings.toml" ${./expected-config.toml}
  '';
}
