{
  imports = [ ./common-stubs.nix ];

  systemd.user.tmpfiles.settings.foo.path.f.argument = "my\\x20unescaped\\x20config";

  test.asserts.warnings.expected = [
    ''
      The 'systemd.user.tmpfiles.settings.foo.path.f.argument' option
      appears to contain escape sequences, which will be escaped again.
      Unescape them if this is not intended. The assigned string is:
        "my\x20unescaped\x20config"
    ''
  ];
}
