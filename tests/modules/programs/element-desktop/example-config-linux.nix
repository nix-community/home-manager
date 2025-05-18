{
  programs.element-desktop = {
    enable = true;
    settings = {
      default_server_config = {
        "m.homeserver" = {
          base_url = "https://matrix-client.matrix.org";
          server_name = "matrix.org";
        };
        "m.identity_server" = {
          base_url = "https://vector.im";
        };
      };
      disable_custom_urls = false;
      disable_guests = false;
      disable_login_language_selector = false;
      disable_3pid_login = false;
      force_verification = false;
      brand = "Element";
      integrations_ui_url = "https://scalar.vector.im/";
      integrations_rest_url = "https://scalar.vector.im/api";
    };
    profiles = {
      work = {
        default_server_config = {
          "m.homeserver" = {
            base_url = "https://matrix-client.matrix.org";
            server_name = "matrix.org";
          };
          "m.identity_server" = {
            base_url = "https://vector.im";
          };
        };
      };
      home = {
        disable_custom_urls = false;
        disable_guests = false;
        disable_login_language_selector = false;
        disable_3pid_login = false;
      };
      other = {
        force_verification = false;
        brand = "Element";
        integrations_ui_url = "https://scalar.vector.im/";
        integrations_rest_url = "https://scalar.vector.im/api";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/Element/config.json
    assertFileExists home-files/.config/Element-work/config.json
    assertFileExists home-files/.config/Element-home/config.json
    assertFileExists home-files/.config/Element-other/config.json

    assertFileContent home-files/.config/Element/config.json \
    ${./cfg/default.json}

    assertFileContent home-files/.config/Element-work/config.json \
    ${./cfg/work.json}

    assertFileContent home-files/.config/Element-home/config.json \
    ${./cfg/home.json}

    assertFileContent home-files/.config/Element-other/config.json \
    ${./cfg/other.json}
  '';
}
