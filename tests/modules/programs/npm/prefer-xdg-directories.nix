{ pkgs, ... }:

{
  home.preferXdgDirectories = true;

  programs.npm = {
    enable = true;
    settings.color = true;
  };

  test.stubs.nodejs = { };

  nmt.script =
    let
      configPath = "home-files/.config/npm/npmrc";
      expectedConfig = pkgs.writeText "npmrc-expected" ''
        color=true
      '';
    in
    ''
      assertFileExists "${configPath}"
      assertFileContent "${configPath}" "${expectedConfig}"
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NPM_CONFIG_USERCONFIG="/home/hm-user/.config/npm/npmrc"'
    '';
}
