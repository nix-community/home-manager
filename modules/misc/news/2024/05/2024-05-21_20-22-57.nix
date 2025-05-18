{ config, ... }:

{
  time = "2024-05-21T20:22:57+00:00";
  condition = config.programs.git.signing != { };
  message = ''

    The Git module now supports signing via SSH and X.509 keys, in addition to OpenPGP/GnuPG,
    via the `programs.git.signing.format` option.

    The format defaults to `openpgp` for now, due to backwards compatibility reasons — this is
    not guaranteed to last! GPG users should manually set `programs.git.signing.format` to
    `openpgp` as soon as possible.

    Accordingly, `programs.git.signing.gpgPath` has been renamed to the more generic option
    `programs.git.signing.signer` as not everyone uses GPG.
    Please migrate to the new option to suppress the generated warning.
  '';
}
