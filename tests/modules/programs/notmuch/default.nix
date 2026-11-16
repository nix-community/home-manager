{
  notmuch-all-sync-producers = ./all-sync-producers.nix;
  notmuch-disabled = ./disabled.nix;
  notmuch-empty-list = ./empty-list.nix;
  notmuch-enabled-only = import ./enabled-only.nix "18.09";
  notmuch-enabled-only-26-11 = import ./enabled-only.nix "26.11";
  notmuch-extra-config-force = ./extra-config-force.nix;
  notmuch-extra-config-list = ./extra-config-list.nix;
  notmuch-legacy = ./legacy.nix;
  notmuch-legacy-modeled = ./legacy-modeled.nix;
  notmuch-null-identity = ./null-identity.nix;
  notmuch-settings = ./settings.nix;
  notmuch-settings-force = ./settings-force.nix;
  notmuch-sync-force = ./sync-force.nix;
  notmuch-sync-lieer = import ./sync.nix "lieer";
  notmuch-sync-mbsync = import ./sync.nix "mbsync";
  notmuch-sync-mujmap = import ./sync.nix "mujmap";
}
