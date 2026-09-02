{
  imports = [ ../../accounts/email-test-accounts.nix ];

  programs.msmtp = {
    enable = true;
    accountOrder = [
      "hm-account"
      "hm-account"
      "hm@example.com"
      "disabled-account"
    ];
  };

  accounts.email.accounts = {
    "hm@example.com".msmtp.enable = true;
    hm-account.msmtp.enable = true;
    aaa = {
      address = "aaa@example.org";
      userName = "aaa";
      passwordCommand = "password-command";
      smtp.host = "smtp.example.org";
      msmtp.enable = true;
    };
  };

  nmt.script = ''
    config=$TESTED/home-files/.config/msmtp/config
    assertFileExists "$config"
    test "$(grep -n '^account hm-account$' "$config" | cut -d: -f1)" -lt \
      "$(grep -n '^account hm@example.com$' "$config" | cut -d: -f1)"
    test "$(grep -n '^account hm@example.com$' "$config" | cut -d: -f1)" -lt \
      "$(grep -n '^account aaa$' "$config" | cut -d: -f1)"
    test "$(grep -c '^account hm-account$' "$config")" = 1
    assertFileNotRegex "$config" '^account disabled-account$'
  '';
}
