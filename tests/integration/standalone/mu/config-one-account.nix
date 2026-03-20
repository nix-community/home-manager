{
  imports = [ ./config-no-accounts.nix ];

  accounts.email.accounts.example = {
    primary = true;
    address = "alice@example.com";
    mu.enable = true;
  };
}
