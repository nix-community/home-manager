{
  imports = [ ./config-one-account.nix ];

  accounts.email.accounts.example2 = {
    address = "alice@example2.com";
    mu.enable = true;
  };
}
