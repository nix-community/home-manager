let name = "firefox";

in builtins.mapAttrs (test: module: import module [ "programs" name ]) {
  "${name}-deprecated-native-messenger" = ./deprecated-native-messenger.nix;
  "${name}-policies" = ./policies.nix;
  "${name}-profile-bookmarks" = ./profiles/bookmarks;
  "${name}-profile-containers" = ./profiles/containers;
  "${name}-profile-containers-duplicate-ids" =
    ./profiles/containers/duplicate-ids.nix;
  "${name}-profile-containers-id-out-of-range" =
    ./profiles/containers/id-out-of-range.nix;
  "${name}-profile-duplicate-ids" = ./profiles/duplicate-ids.nix;
  "${name}-profile-search" = ./profiles/search;
  "${name}-profile-settings" = ./profiles/settings;
  "${name}-state-version-19_09" = ./state-version-19_09.nix;
}
