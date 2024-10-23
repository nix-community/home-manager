{ pkgs, name, agent }:

let
  staging-next-pkgs = import (builtins.fetchTarball { url = "https://github.com/NixOS/nixpkgs/archive/staging-next.tar.gz"; sha256 = "1qv0a78lrgdhic7qr4xvh2c5s0hch3k3ix08ja04pxs2090m0a6n"; }) { inherit (pkgs) system; };

  label = agent.config.Label;

  mainExe = staging-next-pkgs.stdenv.mkDerivation {
    pname = "agent-wrapper-main-executable";
    version = "0.1.0";

    dontUnpack = true;

    nativeBuildInputs = [ staging-next-pkgs.swift ];

    buildInputs = [
      staging-next-pkgs.apple-sdk_13
      (staging-next-pkgs.darwinMinVersionHook "13.0")
    ];

    buildPhase = ''
      swiftc -o $out ${./main.swift}
    '';
  };

  launchAgentPlist = pkgs.writeText "${label}.plist" (pkgs.lib.generators.toPlist {} (agent.config // {
    BundleProgram = "Contents/Resources/LaunchAgent";
  }));
  # launchAgentExe = pkgs.writeShellScript "LaunchAgent" ''
  #   /bin/wait4path /nix/store && exec ${if agent.config ? Program then agent.config.Program else (builtins.elemAt agent.config.ProgramArguments 0)}
  # '';
  launchAgentExe = pkgs.writeShellScript "LaunchAgent" ''
    true
  '';

  infoPlist = pkgs.writeText "Info.plist" (pkgs.lib.generators.toPlist {} {
    CFBundleDevelopmentRegion = "en";
    CFBundleExecutable = "main";
    CFBundleIdentifier = label;
    CFBundleInfoDictionaryVersion = "6.0";
    CFBundleName = name;
    CFBundlePackageType = "APPL";
    CFBundleShortVersionString = "1.0";
    CFBundleSupportedPlatforms = [ "MacOSX" ];
    CFBUndleVersion = "1";
    # CFBundleIconFile = "Icon.icns"; # Apparently not a problem if you have this key but not the icon? Maybe should be optional anyway
  });
  wrapper-app = pkgs.runCommand "${name}-agent-wrapper.app" {} ''
    echo "Creating app..."
    APP_DIR="$out/Applications/${name}.app"

    echo "Creating Contents/Library/LaunchAgents"
    mkdir -p "$APP_DIR/Contents/Library/LaunchAgents"
    echo "Copying LaunchAgent plist into app"
    cp ${launchAgentPlist} "$APP_DIR/Contents/Library/LaunchAgents/${label}.plist"
    echo "Creating Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/MacOS"
    echo "Copying main executable into app"
    cp ${mainExe} "$APP_DIR/Contents/MacOS/main"
    echo "Creating Contents/Resources"
    mkdir -p "$APP_DIR/Contents/Resources"
    echo "Copying LaunchAgent executable into app"
    cp ${launchAgentExe} "$APP_DIR/Contents/Resources/LaunchAgent"
    echo "Copying Info.plist into app"
    cp ${infoPlist} "$APP_DIR/Contents/Info.plist"

    # cp icon "$APP_DIR/Contents/Resources/Icon.icns"

    echo "App finished at $APP_DIR"

    # I'm not sure if this is necessary but rcodesign was complaining before I did this
    echo "chmod -R 777 -ing app"
    chmod -R 777 "$APP_DIR"

    echo "Codesigning app"
    ${pkgs.rcodesign}/bin/rcodesign sign "$APP_DIR"
  '';
in
  wrapper-app
