{ config, pkgs, ... }:
{
  services.exo = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "exo";
      outPath = "@exo@";
    };
    environmentVariables = {
      EXO_LIBP2P_NAMESPACE = "hm-test";
      EXO_OFFLINE = "true";
    };
    extraArgs = [ "--no-worker" ];
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        plistFile=LaunchAgents/org.nix-community.home.exo.plist

        assertFileExists "$plistFile"
        assertFileRegex "$plistFile" '<key>EXO_LIBP2P_NAMESPACE</key>'
        assertFileRegex "$plistFile" '<string>hm-test</string>'
        assertFileRegex "$plistFile" '<key>EXO_OFFLINE</key>'
        assertFileRegex "$plistFile" '<string>true</string>'
        assertFileRegex "$plistFile" '<string>/bin/wait4path /nix/store &amp;&amp; exec @exo@/bin/exo --no-worker</string>'
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/exo.service

        assertFileExists "$serviceFile"
        assertFileRegex "$serviceFile" 'After=network\.target'
        assertFileRegex "$serviceFile" 'Environment=EXO_LIBP2P_NAMESPACE=hm-test'
        assertFileRegex "$serviceFile" 'Environment=EXO_OFFLINE=true'
        assertFileRegex "$serviceFile" 'ExecStart=@exo@/bin/exo --no-worker'
        assertFileRegex "$serviceFile" 'Restart=on-failure'
      '';
}
