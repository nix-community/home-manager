# News {#sec-news}

Home Manager includes a system for presenting news to the user. When
making a change you, therefore, have the option to also include an
associated news entry. In general, a news entry should only be added for
truly noteworthy news. For example, a bug fix or new option does
generally not need a news entry.

Release notes and news entries serve different purposes. A news entry is
shown during Home Manager activation and is useful for day-to-day
communication about noteworthy changes, such as a new module, a new
feature, or a specific deprecation. Release notes are read from the
website documentation and should summarize what users need to know before
or during a stable-release upgrade. See
[Release Notes](release-notes.md#sec-contributing-release-notes) for guidance on changes
that affect stable-release upgrades.

If you do have a change worthy of a news entry then please add one in
[`news`](https://github.com/nix-community/home-manager/blob/master/modules/misc/news)
but you should follow some basic guidelines:

-   Use the included news entry generator to create a news entry file:

    ``` shell
    $ nix run .#create-news-entry
    ```

    Alternatively, you can directly use the script:

    ``` shell
    $ nix-shell -A dev --run modules/misc/news/create-news-entry.sh
    ```

    This will create a new file inside the `modules/misc/news` directory
    with some placeholder information that you can edit.

-   The entry condition should be as specific as possible for changes
    affecting existing functionality. For example, if you are changing
    or deprecating a specific option then you could restrict the news to
    those users who actually use this option. Prefer a targeted
    condition over skipping useful news only to avoid notifying
    unaffected users.

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

    Since this news announces newly available functionality, its
    condition should not require `config.services.foo.enable`; otherwise
    users who may want the new module will not see the news.

    If the module is platform specific, e.g., a service module using
    systemd, then a condition like

    ``` nix
    condition = hostPlatform.isLinux;
    ```

    should be added to avoid showing the news on unsupported platforms.
    Use the `create-news-entry` generator described above to scaffold
    this entry as part of your contribution.
