{
  services.flameshot = {
    enable = true;
  };

  nmt.script = ''
    serviceFile="LaunchAgents/org.nix-community.home.flameshot.plist"
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
      	<string>org.nix-community.home.flameshot</string>
      	<key>ProcessType</key>
      	<string>Interactive</string>
      	<key>ProgramArguments</key>
      	<array>
      		<string>/bin/sh</string>
      		<string>-c</string>
      		<string>/bin/wait4path /nix/store &amp;&amp; exec @flameshot@/bin/flameshot</string>
      	</array>
      	<key>RunAtLoad</key>
      	<true/>
      </dict>
      </plist>''}
  '';
}
