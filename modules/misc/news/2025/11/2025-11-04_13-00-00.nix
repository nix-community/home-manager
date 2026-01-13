{
  time = "2025-11-04T13:00:00+00:00";
  condition = true;
  message = ''
    A new module is available: 'programs.opkssh'.

    opkssh is a tool which enables ssh to be used with OpenID Connect allowing SSH access to be managed via identities instead of long-lived SSH keys. It does not replace SSH, but instead generates SSH public keys containing PK Tokens and configures sshd to verify them. These PK Tokens contain standard OpenID Connect ID Tokens.

    This protocol builds on the OpenPubkey which adds user public keys to OpenID Connect without breaking compatibility with existing OpenID Provider.
  '';
}
