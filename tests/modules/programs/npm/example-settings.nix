{ pkgs, ... }:

{
  programs.npm = {
    enable = true;
    npmrc = ''
      prefix = ''${HOME}/.npm
      registry=https://registry.example.com/
      color=true
    '';
    package = null;
  };

  nmt.script =
    let
      configPath = "home-files/.npmrc";
      expectedConfig = pkgs.writeText "npmrc-expected" ''
        prefix = ''${HOME}/.npm
        registry=https://registry.example.com/
        color=true
      '';
    in
    ''
      assertFileExists "${configPath}"
      assertFileContent "${configPath}" "${expectedConfig}"
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NPM_CONFIG_USERCONFIG="/home/hm-user/.npmrc"'
    '';
}
