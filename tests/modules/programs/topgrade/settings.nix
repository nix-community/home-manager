{ lib, ... }:

{
  programs.topgrade = {
    enable = true;

    settings = lib.mkMerge [
      {
        disable = [ "sdkman" "flutter" "node" "nix" "home_manager" ];

        remote_topgrades = [ "backup" "ci" ];

        remote_topgrade_path = "bin/topgrade";
      }

      {
        set_title = false;
        cleanup = true;

        commands = { "Purge unused APT packages" = "sudo apt autoremove"; };
      }
    ];
  };

  test.stubs.topgrade = { };

  nmt.script = ''
    assertFileContent \
      home-files/.config/topgrade.toml \
      ${./settings-expected.toml}
  '';
}
