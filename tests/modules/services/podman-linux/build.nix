{ pkgs, ... }:

{
  imports = [ ./podman-stubs.nix ];

  services.podman = {
    enable = true;
    builds = {
      "my-bld" = {
        file = let
          containerFile = pkgs.writeTextFile {
            name = "Containerfile";
            text = ''
              FROM docker.io/alpine:latest
            '';
          };
        in "${containerFile}";
      };

      "my-bld-2" = {
        file = "https://www.github.com/././Containerfile";
        extraConfig = {
          Build.ImageTag = [ "locahost/somethingelse" "localhost/anothertag" ];
        };
      };
    };
  };

  test.asserts.assertions.expected = [
    ''
      In 'my-bld-2' config. Build.ImageTag: '[ "locahost/somethingelse" "localhost/anothertag" ]' does not contain 'homemanager/my-bld-2'.''
  ];

  nmt.script = ''
    configPath=home-files/.config/systemd/user
    buildFile=$configPath/podman-my-bld-build.service

    assertFileExists $buildFile

    buildFile=$(normalizeStorePaths $buildFile)

    assertFileContent $buildFile ${./build-expected.service}
  '';
}
