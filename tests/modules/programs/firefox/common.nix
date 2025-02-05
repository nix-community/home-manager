name:
builtins.mapAttrs (test: module: import module [ "programs" name ]) {
  "${name}-deprecated-native-messenger" = ./deprecated-native-messenger.nix;
  "${name}-final-package" = ./final-package.nix;
  "${name}-policies" = ./policies.nix;
  "${name}-profiles-bookmarks" = ./profiles/bookmarks;
  "${name}-profiles-containers" = ./profiles/containers;
  "${name}-profiles-containers-duplicate-ids" =
    ./profiles/containers/duplicate-ids.nix;
  "${name}-profiles-containers-id-out-of-range" =
    ./profiles/containers/id-out-of-range.nix;
  "${name}-profiles-duplicate-ids" = ./profiles/duplicate-ids.nix;
  "${name}-profiles-overwrite" = ./profiles/overwrite;
  "${name}-profiles-search" = ./profiles/search;
  "${name}-profiles-settings" = ./profiles/settings;
  "${name}-state-version-19_09" = ./state-version-19_09.nix;
  "${name}-profiles-shared-path" = ./profiles/shared-path.nix;
}
