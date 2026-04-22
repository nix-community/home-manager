{ config, lib, ... }:
let
  chromePackage =
    let
      mkPackage =
        {
          commandLineArgs ? "",
          name,
          plasmaSupport ? false,
        }:
        config.lib.test.mkStubPackage {
          inherit name;
          buildScript = ''
            mkdir -p $out
            cat > $out/override-info <<EOF
            commandLineArgs=${commandLineArgs}
            plasmaSupport=${lib.boolToString plasmaSupport}
            EOF
          '';
          extraAttrs = {
            override =
              args:
              mkPackage {
                commandLineArgs = args.commandLineArgs or "";
                name = "google-chrome-overridden";
                plasmaSupport = args.plasmaSupport or false;
              };
          };
        };
    in
    mkPackage { name = "google-chrome"; };
in
{
  programs.google-chrome = {
    enable = true;
    package = chromePackage;
    commandLineArgs = [
      "--enable-logging=stderr"
      "--ignore-gpu-blocklist"
    ];
    plasmaSupport = true;
  };

  nmt.script = ''
    package=${config.programs.google-chrome.package}
    finalPackage=${config.programs.google-chrome.finalPackage}

    if [[ "$package" == "$finalPackage" ]]; then
      fail "Expected finalPackage ($finalPackage) to differ from package ($package)"
    fi

    assertFileContent \
      "${config.programs.google-chrome.finalPackage}/override-info" \
      ${builtins.toFile "google-chrome-override-info" ''
        commandLineArgs=--enable-logging=stderr --ignore-gpu-blocklist
        plasmaSupport=true
      ''}
  '';
}
