{
  home-services-basic = ./basic.nix;
  home-services-configdata = ./configdata.nix;
  home-services-ghostunnel = ./ghostunnel.nix;

  # FIXME: Re-enable when nixpkgs' PHP-FPM modular service stops defining
  # ExecReload both directly and through systemd.mainExecReload.
  # home-services-php-fpm = ./php-fpm.nix;
}
