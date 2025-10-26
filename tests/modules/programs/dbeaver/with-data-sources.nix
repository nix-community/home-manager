{ pkgs, ... }:

let
  workspaceDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/DBeaverData/workspace6"
    else
      "home-files/.local/share/DBeaverData/workspace6";
in
{
  programs.dbeaver = {
    enable = true;
    dataSourcesSettings = {
      folders = { };
      connections = {
        "postgresql-local" = {
          provider = "postgresql";
          driver = "postgres-jdbc";
          name = "Local PostgreSQL";
          save-password = false;
          configuration = {
            host = "localhost";
            port = "5432";
            database = "mydb";
          };
        };
      };
    };
  };

  nmt.script = ''
    dataSourcesFile=${workspaceDir}/General/.dbeaver/data-sources.json
    assertFileExists $dataSourcesFile
    assertFileContent $dataSourcesFile ${builtins.toFile "expected" ''
      {
        "connections": {
          "postgresql-local": {
            "configuration": {
              "database": "mydb",
              "host": "localhost",
              "port": "5432"
            },
            "driver": "postgres-jdbc",
            "name": "Local PostgreSQL",
            "provider": "postgresql",
            "save-password": false
          }
        },
        "folders": {}
      }
    ''}
  '';
}
