let name = "firefox";

in builtins.mapAttrs (test: module: import module [ "programs" name ]) {
  "${name}-profile-settings" = ./profile-settings.nix;
  "${name}-state-version-19_09" = ./state-version-19_09.nix;
  "${name}-deprecated-native-messenger" = ./deprecated-native-messenger.nix;
  "${name}-duplicate-profile-ids" = ./duplicate-profile-ids.nix;
  "${name}-duplicate-container-ids" = ./duplicate-container-ids.nix;
  "${name}-container-id-out-of-range" = ./container-id-out-of-range.nix;
  "${name}-policies" = ./policies.nix;
}
