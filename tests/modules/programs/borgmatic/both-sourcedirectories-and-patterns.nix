{ lib, realPkgs, ... }:
{
  programs.borgmatic = {
    enable = true;
    backups.main.location = {
      sourceDirectories = [ "/my-stuff-to-backup" ];
      extraConfig.patterns = [ "- **/.cache" ];
      repositories = [ "/mnt/disk1" ];
    };
  };

  test.asserts.warnings.expected = (import ./warnings.nix { inherit lib; }) {
    file = ./both-sourcedirectories-and-patterns.nix;
    entries = [
      { from = "location.extraConfig"; }
      {
        from = "location.repositories";
        to = "settings.repositories";
        changed = true;
      }
      {
        from = "location.sourceDirectories";
        to = "settings.source_directories";
      }
    ];
  };

  nmt.script = ''
    config_file=$TESTED/home-files/.config/borgmatic.d/main.yaml
    assertFileExists "$config_file"
    ${realPkgs.jq}/bin/jq --exit-status '
      .source_directories == ["/my-stuff-to-backup"] and
      .patterns == ["- **/.cache"] and
      .repositories == [{"path": "/mnt/disk1"}]
    ' "$config_file"
  '';
}
