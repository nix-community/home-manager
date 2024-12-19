{
  imports = [ ./config-one-account.nix ];

  accounts.email.accounts.example.aliases = [ "alias@example.com" ];
}
