{
  programs = {
    nushell.enable = true;
    starship.enable = true;
  };

  nmt.script = ''
    assertFileContains home-files/.config/nushell/config.nu \
      'starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")'
  '';
}
