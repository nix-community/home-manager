{
  time = "2025-12-11T13:45:59+00:00";
  condition = true;
  message = ''
    BREAKING CHANGE:

    home-manager.useGlobalPkgs is true by default and will become ineffective after 26.11.
    Using a different set of pkgs for home-manager and nixos has been a constant source of confusion
    for newcomers and does not make a lot of sense so we are getting rid of this option.
  '';
}
