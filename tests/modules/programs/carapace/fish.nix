{ config, lib, realPkgs, ... }:

lib.mkIf config.test.enableBig {
  programs = {
    carapace.enable = true;
    fish.enable = true;
  };

  nixpkgs.overlays = [ (self: super: { inherit (realPkgs) carapace; }) ];

  nmt.script = let
    needsCompletionOverrides = lib.versionOlder realPkgs.fish.version "4.0.0";
  in ''
    assertFileExists home-files/.config/fish/config.fish
    assertFileRegex home-files/.config/fish/config.fish \
      '/nix/store/.*carapace.*/bin/carapace _carapace fish \| source'
  '' + (lib.optionalString needsCompletionOverrides ''
    # Check whether completions are overridden, necessary for fish < 4.0
    assertFileExists home-files/.config/fish/completions/git.fish
    assertFileContent home-files/.config/fish/completions/git.fish /dev/null
  '') + (lib.optionalString (!needsCompletionOverrides) ''
    assertPathNotExists home-files/.config/fish/completions
  '');
}
