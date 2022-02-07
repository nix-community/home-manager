# This is a test primarily concerned with the order of the configuration. The
# configuration is dynamically generated in alphabetical order of the top-level
# attribute names. Because of this, it is possible to override top-level
# attributes that are supposed to be configured in the top-level configuration.
{ config, ... }:

{
  services.recoll = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    settings = {
      a = { foo = "bar"; };
      b = 10;
      c = {
        a = "This should appear as the second section.";
        b = 53;
        aa = true;
      };
      d = false;
      e =
        "This should be the second to the last non-attrset value in the config.";
      f = {
        a =
          "This should be second to the last for the attribute names with an attrset.";
        b = 3193;
        c = false;
        d = [ "Hello" "there" ];
      };
      foo = {
        bar = "This should be the last attribute with an attrset.";
        baz = 42;
      };
      g = [ "This" "is" "coming" "from" "a" "list" ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/recollindex.service
    assertFileExists home-files/.config/systemd/user/recollindex.timer

    assertFileExists home-files/.recoll/recoll.conf
    assertFileContent home-files/.recoll/recoll.conf \
        ${./config-format-order.conf}
  '';
}
