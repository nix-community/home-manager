{ config, pkgs, ... }:
let
  cfg = config.services.proton-pass-agent;
in
{
  services.proton-pass-agent = {
    enable = true;
    socket = "proton-pass-agent/socket";
    share-id = "123456789";
    vault-name = "MySshKeyVault";
    refresh-interval = 7200;
    create-new-identities = "MySshKeyVault";
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        plistFile=LaunchAgents/org.nix-community.home.ssh-agent.plist

        assertFileExists $plistFile
        assertFileContent $plistFile  ${builtins.toFile "expected-plist" ''
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
          	<string>org.nix-community.home.ssh-agent</string>
          	<key>ProcessType</key>
          	<string>Background</string>
          	<key>ProgramArguments</key>
          	<array>
          			<string>@bash-interactive@/bin/bash</string>
            		<string>-c</string>
            		<string>@proton-pass-cli@/bin/pass-cli ssh-agent start --socket-path &quot;$(@getconf-system_cmds@/bin/getconf DARWIN_USER_TEMP_DIR)/ssh-agent&quot; --share-id ${cfg.share-id} --vault-name ${cfg.vault-name} --refresh-interval ${toString cfg.refresh-interval} --create-new-identities ${cfg.create-new-identities}</string>
          	</array>
          	<key>RunAtLoad</key>
          	<true/>
          </dict>
          </plist>
        ''}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/proton-pass-agent.service

        assertFileExists $serviceFile
        assertFileContent $serviceFile  ${builtins.toFile "expected-service" ''
          [Install]
          WantedBy=default.target

          [Service]
          ExecStart=@proton-pass-cli@/bin/pass-cli ssh-agent start --socket-path $XDG_RUNTIME_DIR/${cfg.socket} --share-id ${cfg.share-id} --vault-name ${cfg.vault-name} --refresh-interval ${toString cfg.refresh-interval} --create-new-identities ${cfg.create-new-identities}

          [Unit]
          Description=Proton Pass SSH agent
        ''}
      '';
}
