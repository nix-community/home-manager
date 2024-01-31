# News {#sec-news}

Home Manager includes a system for presenting news to the user. When
making a change you, therefore, have the option to also include an
associated news entry. In general, a news entry should only be added for
truly noteworthy news. For example, a bug fix or new option does
generally not need a news entry.

If you do have a change worthy of a news entry then please add one in
[`news.nix`](https://github.com/nix-community/home-manager/blob/master/modules/misc/news.nix)
but you should follow some basic guidelines:

-   The entry timestamp should be in ISO-8601 format having \"+00:00\"
    as time zone. For example, \"2017-09-13T17:10:14+00:00\". A suitable
    timestamp can be produced by the command

    ``` shell
    $ date --iso-8601=second --universal
    ```

-   The entry condition should be as specific as possible. For example,
    if you are changing or deprecating a specific option then you could
    restrict the news to those users who actually use this option.

-   Wrap the news message so that it will fit in the typical terminal,
    that is, at most 80 characters wide. Ideally a bit less.

-   Unlike commit messages, news will be read without any connection to
    the Home Manager source code. It is therefore important to make the
    message understandable in isolation and to those who do not have
    knowledge of the Home Manager internals. To this end it should be
    written in more descriptive, prose like way.

-   If you refer to an option then write its full attribute path. That
    is, instead of writing

        The option 'foo' has been deprecated, please use 'bar' instead.

    it should read

        The option 'services.myservice.foo' has been deprecated, please
        use 'services.myservice.bar' instead.

-   A new module, say `foo.nix`, should always include a news entry that
    has a message along the lines of

        A new module is available: 'services.foo'.

    If the module is platform specific, e.g., a service module using
    systemd, then a condition like

    ``` nix
    condition = hostPlatform.isLinux;
    ```

    should be added. If you contribute a module then you don't need to
    add this entry, the merger will create an entry for you.
