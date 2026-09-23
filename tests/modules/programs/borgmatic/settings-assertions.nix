{ lib, realPkgs, ... }:
{
  programs.borgmatic = {
    enable = true;
    package = null;
    backups = {
      missingRepository.settings.source_directories = [ "/source" ];
      missingLegacyRepository.location.sourceDirectories = [ "/source" ];
      effective.settings = {
        repositories = [ { path = "/repo"; } ];
        postgresql_databases = [ { name = "native"; } ];
      };
    };
  };
  test.asserts.assertions.expected = [
    ''
      Borgmatic backup configuration "missingLegacyRepository" must specify 'settings.repositories' (or the deprecated 'location.repositories').
    ''
    ''
      Borgmatic backup configuration "missingRepository" must specify 'settings.repositories' (or the deprecated 'location.repositories').
    ''
  ];

  test.asserts.warnings.expected = (import ./warnings.nix { inherit lib; }) {
    file = ./settings-assertions.nix;
    backup = "missingLegacyRepository";
    entries = [
      {
        from = "location.sourceDirectories";
        to = "settings.source_directories";
      }
    ];
  };

  nmt.script = ''
    config_file=$TESTED/home-files/.config/borgmatic.d/effective.yaml
    assertFileExists "$config_file"
    ${realPkgs.jq}/bin/jq --exit-status '
      (has("source_directories") | not) and
      (has("patterns") | not) and
      .postgresql_databases == [{"name": "native"}] and
      .repositories == [{"path": "/repo"}]
    ' "$config_file"
  '';
}
