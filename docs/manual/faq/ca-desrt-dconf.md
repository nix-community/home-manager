# Why do I get an error message about `ca.desrt.dconf` or `dconf.service`? {#_why_do_i_get_an_error_message_about_literal_ca_desrt_dconf_literal_or_literal_dconf_service_literal}

You are most likely trying to configure something that uses dconf but
the DBus session is not aware of the dconf service. The full error you
might get is

    error: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name ca.desrt.dconf was not provided by any .service files

or

    error: GDBus.Error:org.freedesktop.systemd1.NoSuchUnit: Unit dconf.service not found.

The solution on NixOS is to add

``` nix
programs.dconf.enable = true;
```

to your system configuration.
