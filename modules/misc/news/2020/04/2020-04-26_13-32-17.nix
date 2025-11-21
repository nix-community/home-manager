{
  time = "2020-04-26T13:32:17+00:00";
  condition = true;
  message = ''

    A number of new modules are available:

      - 'accounts.calendar',
      - 'accounts.contact',
      - 'programs.khal',
      - 'programs.vdirsyncer', and
      - 'services.vdirsyncer' (Linux only).

    The two first modules offer a number of options for
    configuring calendar and contact accounts. This includes,
    for example, information about carddav and caldav servers.

    The khal and vdirsyncer modules make use of this new account
    infrastructure.

    Note, these module are still somewhat experimental and their
    structure should not be seen as final, some modifications
    may be necessary as new modules are added.
  '';
}
