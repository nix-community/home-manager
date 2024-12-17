{ lib, ... }: {
  imports = [ ./config-two-accounts.nix ];

  accounts.email.accounts.example2.mu.enable = lib.mkForce false;
}
