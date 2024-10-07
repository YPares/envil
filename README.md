[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2FYPares%2Fenvil%3Fbranch%3Dmaster)](https://garnix.io/repo/YPares/envil)

# envil

```ascii
      , `. ,'
       `.',
   ---||;
     ====
.--------------,
 \___.      __/
     |_____/
```

**envil** forges Nix flakes.

This is a tool to:

- generate simple Nix flakes from a simple yaml description of a set of environments (see for instance [here](./examples/statedir/envil-state.yaml)),
- switch to a specific environment (add the tools that an env contains to your `PATH` and remove those of the previously activated env),
- start a subshell with a specific env activated.

It aims at providing people who are not regular Nix users a quick and simple way to start with custom,
isolated & reproducible environments, one of the major reasons to use Nix.

This is **not** a tool to:

- install and manage Nix for you,
- write complicated Nix logic for you

Also, it's not just meant for Nix beginners: if you already know Nix,
you may have still a use for it, as a small "top-level" flake manager, to be able to quickly switch between environments and/or
tools you would already have defined as flake files.
That is because in its current state, `envil` aims at being an alternative to the `nix profile` command, which doesn't support
multiple profiles and contributes to cluttering your PATH. `envil` enables you and incites you to be selective and to
quickly switch between environments or start shells to avoid situations where you end up with two different versions
of the same tool in your `PATH`, or things like two different `python` installations but each one configured with its own libraries,
leaving you unable to select which one you want.

## Setup

To install `envil`, first you need to [install Nix](https://determinate.systems/nix/). Then just do:

```sh
nix profile install github:YPares/envil#envil
```

to have `envil` available in your `PATH`. Alternatively, you can run `nix run github:YPares/envil` everytime you want to use `envil`.

If you want to use the `envil switch` command, add the following to your `.profile`:

```sh
PATH="$HOME/.envil/current/bin:$PATH"
```

and then log out and log back in.

By default, `envil` will read/write its configuration in `$HOME/.envil`.
This is what `envil` calls a "statedir", ie. a directory that contains (1) a certain configuration representing the
desired state of several environments, and (2) the Nix flakes it generated for those environments.

Run `envil -h` to see all the commands available. For instance, if you clone that repo and `cd` into your local clone,
you can run the following:

- `envil envs -d examples/statedir`: list all the envs defined in the example statedir
- `envil shell -d examples/statedir`: show a list of all envs in the example statedir and let you select one.
  Then open a subshell, where the tools from the selected env are in your `PATH`
- `envil update some-env`: reads your own `~/.envil` statedir (the default without a `-d`), tries to find an env
  named "`some-env`" and updates its flake.lock file. You can then rerun `envil shell` or `envil switch` to get
  the updated packages

Subshells export the `$SHELL_ENV` env var. You can use it in your shell prompt (eg. `PS1` for bash) so it shows
which env is activated in the subshell. For instance if you use bash, add the following to your `.bashrc`:

```bash
if [[ -n "$SHELL_ENV" ]]; then
    shell_env_bit='\e[0;33m[$SHELL_ENV($SHLVL)]\e[0m'
fi

PS1="${shell_env_bit}...the rest of your prompt..."
```

(`$SHLVL` is a standard env var telling you how many levels of subshells you are currently in)

## Updating `envil`

Do `nix profile upgrade envil --refresh`.

## Roadmap

- Add commands to manipulate the yaml state, so manual edition is no longer needed.
- Add a protection against same exe being twice in your PATH

## Related tools & philosophy

`envil` is related to [`devenv`](https://devenv.sh/), [`devbox`](https://www.jetify.com/docs/devbox/),
[`flox`](https://flox.dev/), [`flakey-profile`](https://github.com/lf-/flakey-profile) and
[`home-manager`](https://github.com/nix-community/home-manager) but with a focus on:

- simplicity and usability by people who do not write or write little Nix code;
- compatibility with existing Nix tools, and no disruption of your regular Nix installation:
  `envil` will not manage Nix installation for you,
  there are better tools to do that, such as the Determinate Systems Nix installer linked above. Likewise, `envil`
  will not manage your nix profile like `flakey-profile` does. It operates on the side so you can keep using
  `nix-env` or `nix profile` as usual;
- reusable environments, meaning that any env can extend (or import, include, whatever you prefer) other envs;
- production of regular and (almost) idiomatic Nix flakes that do not require `--impure`

Also, `envil` strongly encourages decomposition. If you write Nix code, then writing small & local Nix flakes to
then reuse them in `envil` envs is perfectly encouraged. `envil` will not write complicated Nix logic for you,
just the classic boilerplate needed to define a top-level flake with some `pkgs.buildEnv` calls.

`envil` will not do anything to track versions of environments. It represents its state as a very simple yaml file,
therefore versioning can just be done with `git`.
