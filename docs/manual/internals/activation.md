# Activation {#sec-internals-activation}

Activating a Home Manager configuration ensures that the built
configuration is introduced into the user's environment. The
activation is performed by a suitably named script
{command}`activate`. This script is generated as part of the
configuration build and is placed in the root of the build output.

The activation script is implemented in the Bash language and consists
of initialization code followed by a number of _activation script
blocks_. These blocks are specified using the
[home.activation](#opt-home.activation) option. The blocks may have
dependencies among themselves and the generated activation script will
contain the blocks serialized such that the dependencies are
satisfied. A dependency cycle causes a failure when the configuration
is built.

Historically, the activation script has been responsible for creating
a new generation of the `home-manager` Nix profile. The more modern
way, however, is to let the _activation driver_ – that is, the
software calling the activation script – manage the profile. Indeed,
in some cases we may not have a `home-manager` profile at all! This is
the case when Home Manager is used as a NixOS or nix-darwin module, in
these cases the system profile will contain references to the
corresponding Home Manager configurations.

Note, to maintain backwards compatibility, the old activation script
behavior is still the default. To choose the new mode of operation you
have to call the activation script with the command line option
`--driver-version 1`. The old behavior is available using
`--driver-version 0`, or simply omit it entirely.

Unfortunately, driver software need to support both modes of operation
for the time being since a user may wish to activate an old generation
that contains an activation script that does not support
`--driver-version`. To determine whether support is available, check
the {file}`gen-version` file in the configuration build output root.
If the file is missing then the activation script does not support
`--driver-version`. If the file exists and contains the integer 1 or
higher, then `--driver-version 1` is supported.

The activation script also accepts the command line option
`--files-only`. It then runs only the activation script blocks named
in [home.activationFilesOnly](#opt-home.activationFilesOnly), in their
usual order. By default these are the blocks that place
[home.file](#opt-home.file): `checkFilesChanged`, `checkLinkTargets`,
`linkGeneration` and `onFilesChange`, and every block that must run
before `linkGeneration`, since such blocks prepare the files' targets.
Such a run makes no Nix calls and uses no Nix profile: it does not
check the Nix store, look up or manage a profile or create a garbage
collection root, so it also works on an account that never had a full
activation. It leaves packages, services and every other block alone,
and it does not record the generation as activated.

A files-only run is meant to be followed by a full activation of the
same generation, which then finds the files in place, runs no
`onChange` hook again, except those of recursive entries, which always
run, and completes the switch. A driver can use this to apply a change
quickly, for example when switching between specialisations that
differ in their files, and run the rest of the activation afterwards.
Until then, the packages and services of the previous generation
remain, and the caller has to keep the generation from being garbage
collected. No other activation may run in between: every activation
compares against the generation of the last full one, so the files
that only the files-only run placed would stay behind.

Pass `--files-only` only to generations built by a Home Manager that
supports it. Generations without a {file}`gen-version` file ignore the
option and run a full activation, and later ones built before the
option existed reject it as unknown.
