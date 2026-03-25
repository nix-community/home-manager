{
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.config/pipewire'
    assertPathNotExists 'home-files/.config/wireplumber'
    assertPathNotExists 'home-files/.local/share/wireplumber'
  '';
}
