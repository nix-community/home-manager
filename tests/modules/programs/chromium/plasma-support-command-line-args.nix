{
  config,
  lib,
  pkgs,
  ...
}:
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

  plasmaBrowserIntegrationPackage = config.lib.test.mkStubPackage {
    name = "plasma-browser-integration";
    buildScript = ''
      mkdir -p $out/etc/chromium/native-messaging-hosts
      echo test > $out/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json
    '';
  };

  nativeHostsDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/Google/Chrome/NativeMessagingHosts"
    else
      ".config/google-chrome/NativeMessagingHosts";

  nativeHostAssertion =
    if pkgs.stdenv.hostPlatform.isLinux then
      ''
        assertFileExists \
          "home-files/${nativeHostsDir}/org.kde.plasma.browser_integration.json"
      ''
    else
      ''
        assertPathNotExists \
          "home-files/${nativeHostsDir}/org.kde.plasma.browser_integration.json"
      '';
in
{
  programs.google-chrome = {
    enable = true;
    package = chromePackage;
    commandLineArgs = [
      "--enable-logging=stderr"
      "--ignore-gpu-blocklist"
    ];
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    plasmaSupport = true;
    inherit plasmaBrowserIntegrationPackage;
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
        plasmaSupport=${lib.boolToString pkgs.stdenv.hostPlatform.isLinux}
      ''}

    ${nativeHostAssertion}
  '';
}
