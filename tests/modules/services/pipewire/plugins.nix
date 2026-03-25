{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;

    extraLv2Packages = [
      (pkgs.writeTextDir "lib/lv2/test" ''
        bing bong
      '')
    ];
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.config/pipewire'
    assertPathNotExists 'home-files/.config/wireplumber'
    assertPathNotExists 'home-files/.local/share/wireplumber'

    file='home-files/.config/environment.d/10-home-manager.conf'
    regex='^LV2_PATH=/nix/store/.*/lib/lv2\''${LV2_PATH:+:\$LV2_PATH}$'

    assertFileExists "$file"
    assertFileRegex "$file" "$regex"
  '';
}
