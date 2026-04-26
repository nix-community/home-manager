{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;

    extraLv2Packages = [
      (pkgs.writeTextDir "lib/lv2/test" ''
        bing bong
      '')
    ];

    extraLadspaPackages = [
      (pkgs.writeTextDir "lib/ladspa/test" ''
        bing bong
      '')
    ];
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.config/pipewire'
    assertPathNotExists 'home-files/.config/wireplumber'
    assertPathNotExists 'home-files/.local/share/wireplumber'

    file='home-files/.config/environment.d/10-home-manager.conf'
    lv2regex='^LV2_PATH=/nix/store/.*/lib/lv2\''${LV2_PATH:+:\$LV2_PATH}$'
    ladsparegex='^LADSPA_PATH=/nix/store/.*/lib/ladspa\''${LADSPA_PATH:+:\$LADSPA_PATH}$'

    assertFileExists "$file"
    assertFileRegex "$file" "$lv2regex"
    assertFileRegex "$file" "$ladsparegex"
  '';
}
