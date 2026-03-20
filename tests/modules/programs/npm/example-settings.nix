{ pkgs, ... }:

{
  programs.npm = {
    enable = true;
    settings = {
      color = true;
      include = [
        "dev"
        "prod"
      ];
      init-license = "MIT";
      prefix = "\${HOME}/.npm";
    };
  };

  test.stubs.nodejs = { };

  nmt.script =
    let
      configPath = "home-files/.npmrc";
      expectedConfig = pkgs.writeText "npmrc-expected" ''
        color=true
        include[]=dev
        include[]=prod
        init-license=MIT
        prefix=''${HOME}/.npm
      '';
    in
    ''
      assertFileExists "${configPath}"
      assertFileContent "${configPath}" "${expectedConfig}"
      assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
        'export NPM_CONFIG_USERCONFIG="/home/hm-user/.npmrc"'
    '';
}
