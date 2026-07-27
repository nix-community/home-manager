{
  # Disabled for now due to conflicting behavior with nix-darwin. See
  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-687286866
  #targets-darwin = ./darwin.nix;
  terminfo = ./terminfo.nix;
  terminfo-disabled-override = ./terminfo-disabled-override.nix;
  terminfo-null = ./terminfo-null.nix;
  terminfo-override = ./terminfo-override.nix;
  user-defaults = ./user-defaults.nix;
}
