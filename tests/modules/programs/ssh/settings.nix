{ config, lib, ... }:
{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        github = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/github";
          IdentityAgent = [
            "~/.ssh/agent"
            "SSH_AUTH_SOCK"
          ];
          CertificateFile = [
            "~/.ssh/github-cert.pub"
            "~/.ssh/github-alt-cert.pub"
          ];
          IdentitiesOnly = true;
        };

        "Host *.corp !bastion.corp" = lib.hm.dag.entryBefore [ "github" ] {
          User = "corp";
          ProxyJump = [
            "bastion-a.corp"
            "bastion-b.corp"
          ];
          SendEnv = [
            "LANG"
            "LC_*"
          ];
        };

        "Match host *.corp exec \"test -f ~/.corp\"" = lib.hm.dag.entryAfter [ "github" ] {
          SetEnv = {
            FOO = "foo";
            BAR = "bar baz";
            BAZ = ''with " some \ very \" fun \\ escapes'';
          };
          IgnoreUnknown = [
            "PubkeyAcceptedAlgorithms"
            "PubkeyAcceptedKeyTypes"
          ];
          Ciphers = [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
          ];
          CASignatureAlgorithms = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          HostbasedAcceptedAlgorithms = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          HostbasedKeyTypes = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          HostKeyAlgorithms = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          KbdInteractiveDevices = [
            "bsdauth"
            "pam"
          ];
          KexAlgorithms = [
            "sntrup761x25519-sha512"
            "mlkem768x25519-sha256"
          ];
          MACs = [
            "hmac-sha2-256-etm@openssh.com"
            "hmac-sha2-512-etm@openssh.com"
          ];
          PreferredAuthentications = [
            "publickey"
            "keyboard-interactive"
          ];
          PubkeyAcceptedAlgorithms = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          PubkeyAcceptedKeyTypes = [
            "ssh-ed25519"
            "rsa-sha2-512"
          ];
          LocalForward = [
            {
              bind.port = 8080;
              host.address = "10.0.0.1";
              host.port = 80;
            }
            "9000 10.0.0.2:90"
          ];
        };
      };
    };

    home.file.assertions.text = builtins.toJSON (
      map (a: a.message) (lib.filter (a: !a.assertion) config.assertions)
    );

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContent \
        home-files/.ssh/config \
        ${./settings-expected.conf}
      assertFileContent home-files/assertions ${./no-assertions.json}
    '';
  };
}
