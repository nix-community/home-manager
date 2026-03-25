{ pkgs, ... }:

let
  inherit (pkgs) writeText;

  expectedValue = ''
    print("Hello, world!")
  '';

  expectedValuePath = writeText "expected-wireplumber-script" expectedValue;
in

{
  services.pipewire = {
    enable = true;
    wireplumber = {
      enable = true;
      scripts = {
        "foo/hello-world.lua" = expectedValue;
        "bar/hello-world.lua" = expectedValue;
      };
      scriptPackages = [
        (pkgs.writeTextDir "share/wireplumber/scripts/baz/hello-world.lua" expectedValue)
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists 'home-files/.config/pipewire'
    assertPathNotExists 'home-files/.config/wireplumber'

    local expected=${expectedValuePath}

    local scripts=(
      'foo/hello-world.lua'
      'bar/hello-world.lua'
      'baz/hello-world.lua'
    )

    for script in $scripts; do
      local file="home-files/.local/share/wireplumber/scripts/$script"

      assertFileExists "$file"
      assertFileContent "$file" "$expected"
    done
  '';
}
