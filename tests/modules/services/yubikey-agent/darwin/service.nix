{ config, ... }:

{
  services.yubikey-agent = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@yubikey-agent@"; };
  };

  nmt.script = ''
    serviceFile=LaunchAgents/org.nix-community.home.yubikey-agent.plist
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${builtins.toFile "expected-agent.plist" ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      	<key>KeepAlive</key>
      	<dict>
      		<key>Crashed</key>
      		<true/>
      		<key>SuccessfulExit</key>
      		<false/>
      	</dict>
      	<key>Label</key>
      	<string>org.nix-community.home.yubikey-agent</string>
      	<key>ProcessType</key>
      	<string>Background</string>
      	<key>ProgramArguments</key>
      	<array>
      		<string>@yubikey-agent@/bin/yubikey-agent</string>
      		<string>-l</string>
      		<string>/tmp/yubikey-agent.sock</string>
      	</array>
      	<key>Sockets</key>
      	<dict>
      		<key>Listener</key>
      		<dict>
      			<key>SockPathMode</key>
      			<integer>384</integer>
      			<key>SockPathName</key>
      			<string>/tmp/yubikey-agent.sock</string>
      		</dict>
      	</dict>
      </dict>
      </plist>''}
  '';
}
