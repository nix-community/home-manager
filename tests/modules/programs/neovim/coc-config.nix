{ lib, ... }:

# Currently broken due to a change in Nixpkgs.
lib.mkIf false {
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;
    coc = {
      enable = true;
      settings = {
        # my variable
        foo = "bar";
      };
    };
  };

  nmt.script = ''
    cocSettings="$TESTED/home-files/.config/nvim/coc-settings.json"
    cocSettingsNormalized="$(normalizeStorePaths "$cocSettings")"

    assertFileExists "$cocSettings"
    assertFileContent "$cocSettingsNormalized" "${./coc-config.expected}"
  '';
}

