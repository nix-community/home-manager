{ pkgs, lib, ... }:

let
  jsonFormat = pkgs.formats.json { };

  expectedValue = {
    "foo.bar" = {
      "baz.qux" = true;
    };
    "baz.qux" = {
      "foo.bar" = false;
    };
  };

  expectedValuePath = jsonFormat.generate "expected-pipewire-config" expectedValue;
  expectedValueContent = lib.readFile expectedValuePath;
in

{
  services.pipewire = rec {
    enable = true;

    configs = {
      "10-test" = expectedValue;
      "11-test" = expectedValue;
    };

    clientConfigs = configs;
    jackConfigs = configs;
    pulseConfigs = configs;

    configPackages = [
      (pkgs.writeTextDir "share/pipewire/pipewire.conf.d/12-test.conf" expectedValueContent)
      (pkgs.writeTextDir "share/pipewire/client.conf.d/12-test.conf" expectedValueContent)
      (pkgs.writeTextDir "share/pipewire/jack.conf.d/12-test.conf" expectedValueContent)
      (pkgs.writeTextDir "share/pipewire/pipewire-pulse.conf.d/12-test.conf" expectedValueContent)
    ];

    wireplumber = {
      enable = true;
      configs = configs;
      configPackages = [
        (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/12-test.conf" expectedValueContent)
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.local/share/wireplumber'

    local expected=${expectedValuePath}

    local names=(
      '10-test.conf'
      '11-test.conf'
      '12-test.conf'
    )

    local subdirs=(
      'pipewire/pipewire.conf.d'
      'pipewire/client.conf.d'
      'pipewire/jack.conf.d'
      'pipewire/pipewire-pulse.conf.d'
      'wireplumber/wireplumber.conf.d'
    )

    for subdir in $subdirs; do
      for name in $names; do
        local file="home-files/.config/$subdir/$name"

        assertFileExists "$file"
        assertFileContent "$file" "$expected"
      done
    done
  '';
}
