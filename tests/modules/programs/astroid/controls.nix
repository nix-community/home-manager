{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com" = {
    astroid.enable = true;
    notmuch.enable = true;
    msmtp.enable = true;
    signature = {
      showSignature = "attach";
      text = "Test signature";
    };
    gpg = {
      key = "test-key";
      signByDefault = true;
    };
    astroid.extraConfig.select_query = "tag:inbox";
  };

  programs.astroid = {
    enable = true;
    pollScript = "fetch-mail";
  };

  assertions = [
    {
      assertion = lib.elem config.programs.astroid.package config.home.packages;
      message = "Astroid must install its configured package.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContent "$(normalizeStorePaths home-files/.config/astroid/config)" ${./controls.json}
    assertFileExists home-files/.config/astroid/poll.sh
    assertFileContains home-files/.config/astroid/poll.sh 'fetch-mail'
    test -x "$TESTED/home-files/.config/astroid/poll.sh"
    ${pkgs.jq}/bin/jq -e '
      .accounts["hm@example.com"] as $account
      | $account.sendmail == "msmtpq --read-envelope-from --read-recipients"
      and $account.email == "hm@example.com" and $account.default == "true"
      and $account.signature_attach == "true" and $account.signature_default_on == "true"
      and $account.signature_file_markdown == "false" and $account.signature_separate == "true"
      and $account.gpgkey == "test-key" and $account.always_gpg_sign == "true"
      and $account.select_query == "tag:inbox"
      and (.accounts | keys) == ["hm@example.com"]
    ' "$TESTED/home-files/.config/astroid/config"
    signature=$(${pkgs.jq}/bin/jq -r '.accounts["hm@example.com"].signature_file' "$TESTED/home-files/.config/astroid/config")
    diff -u "$signature" ${pkgs.writeText "expected-signature" "Test signature"}
  '';
}
