{ lib, realPkgs, ... }: {
  imports = [ ./stubs.nix ];

  # TODO: remove after stubbing `withPackages`
  _module.args.pkgs = lib.mkForce realPkgs;

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

