{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com".notmuch.enable = true;

  programs.notmuch = {
    enable = true;
    settings.user = {
      name = null;
      primary_email = null;
    };
  };

  test.asserts.warnings.expected = [ ];

  test.asserts.assertions.expected = [
    "notmuch: Must have a user name set."
    "notmuch: Must have a user primary email address set."
  ];
}
