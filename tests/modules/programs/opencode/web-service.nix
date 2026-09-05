{
  config,
  lib,
  pkgs,
  ...
}:
let
  profileHelper = pkgs.writeShellScriptBin "profile-helper" "";
  extraHelper = pkgs.writeShellScriptBin "extra-helper" "";
  inheritedHelper = pkgs.writeShellScriptBin "inherited-helper" "";
  testOpencode = pkgs.writeShellScriptBin "opencode" ''
    command -v profile-helper >/dev/null
    command -v extra-helper >/dev/null
    command -v inherited-helper >/dev/null
  '';
  serviceLauncher = config.systemd.user.services.opencode-web.Service.ExecStart;
  testLauncher = "$TMPDIR/opencode-web-launcher";
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  programs.opencode = {
    enable = true;
    package = testOpencode;
    extraPackages = [ extraHelper ];

    web = {
      enable = true;
      extraArgs = [
        "--hostname"
        "0.0.0.0"
        "--port"
        "4096"
        "--mdns"
        "--cors"
        "https://example.com"
        "--cors"
        "http://localhost:3000"
        "--print-logs"
        "--log-level"
        "DEBUG"
      ];
    };
  };

  nmt.script =
    (
      if pkgs.stdenv.hostPlatform.isDarwin then
        ''
          serviceFile=LaunchAgents/org.nix-community.home.opencode-web.plist
          assertFileExists "$serviceFile"
          serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
          assertFileContent "$serviceFileNormalized" ${./web-service.plist}
        ''
      else
        ''
          serviceFile=home-files/.config/systemd/user/opencode-web.service
          assertFileExists "$serviceFile"
          serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
          assertFileContent "$serviceFileNormalized" ${./web-service.service}
        ''
    )
    + ''
      mkdir -p "$TMPDIR/hm-user/.nix-profile/bin"
      ln -s ${lib.getExe profileHelper} "$TMPDIR/hm-user/.nix-profile/bin/profile-helper"
      substitute ${lib.escapeShellArg serviceLauncher} ${testLauncher} --subst-var TMPDIR
      chmod +x ${testLauncher}
      PATH=${lib.makeBinPath [ inheritedHelper ]} ${testLauncher}
    '';
}
