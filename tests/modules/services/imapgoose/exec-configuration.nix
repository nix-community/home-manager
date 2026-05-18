{ config, pkgs, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts."hm@example.com" = {
    maildir.path = "hm-example.com";
    imapgoose.enable = true;
  };

  programs.imapgoose = {
    package = config.lib.test.mkStubPackage {
      name = "imapgoose";
      outPath = "@imapgoose@";
    };
  };

  services.imapgoose = {
    enable = true;
    frequency = "hourly";
    preExec = ''
      echo "pre-exec 1"
      echo "pre-exec 2"
    '';
    postExec = ''
      echo "post-exec 1"
    '';
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isLinux then
      ''
        serviceFile="home-files/.config/systemd/user/imapgoose.service"
        assertFileExists "$serviceFile"
        assertFileRegex "$serviceFile" "ExecStartPre=.*/bin/sleep 1m"
        assertFileRegex "$serviceFile" "ExecStartPre=.*/nix/store/.*-imapgoose-pre-exec"
        assertFileRegex "$serviceFile" "ExecStartPost=.*/nix/store/.*-imapgoose-post-exec"
      ''
    else
      ''
        serviceFile="LaunchAgents/org.nix-community.home.imapgoose.plist"
        assertFileExists "$serviceFile"
        assertFileRegex "$serviceFile" "<string>.*/nix/store/.*-imapgoose-run</string>"
      '';
}
