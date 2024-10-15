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

`envil` is a tool to:

- generate simple Nix flakes from a simple yaml description of a set of environments (see for instance [here](./examples/statedir/envil-state.yaml)),
- switch to a specific environment (add the tools that this env contains to your `PATH`, and remove those of the previously activated env),
  or add it on top of currently activated envs,
- start a subshell with a specific set of envs activated.

In the Nix ecosystem, a _flake_ is a file that describes a set of tools and programs ("outputs") for various possible systems,
how to build those programs, and what is needed to build them ("inputs"). Nix is actually a fairly generic programming language,
which is why some seemingly simple use cases (such as listing a fixed set of pre-existing packages in a flake and installing them) may appear more complex
to tackle than they need to.

`envil` targets some of those simple use cases. It aims at providing people who are not regular Nix users a quick way to start with custom,
isolated & reproducible (ie. "rebuildable identically elsewhere") environments, one of the major reasons to use Nix.

`envil` is **not** a tool to:

- install and manage Nix for you,
- write complicated Nix logic for you.

Also, it's not just meant for Nix beginners: if you already know Nix,
you may have still a use for it, as a small "top-level" flake manager, to be able to quickly switch between environments and/or
tools you would already have defined as flake files.
That is because in its current state, `envil` aims at being an alternative to the `nix profile` command, which makes inconvenient to work with
multiple profiles and contributes to cluttering your PATH. Conversely, `envil` enables you and incites you to be selective and to
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

`envil` will read & write its current state in `$HOME/.envil`. As hinted above, it is in that folder that envil will put the
symlinks to the bins of your currently activated environment, and therefore why you need to add it to your `PATH`.

`envil` manages environments as a _stack_. That means several envs can be activated at the same time. The main commands to interact with it
are `envil add` and `envil pop` to add or remove envs from the stack, and `envil status` to view its current state.

Besides this, `envil` has a notion of _statedir_. That is any directory that contains (1) an `envil-state.yaml` file, i.e. a config file representing the
desired state of several environments, and (2) the Nix flakes generated by `envil` for those environments, each one in their own folder.
`envil switch` is the command that allows to change the currently used statedir, registering it so subsequent uses of `evil add`/`pop` know about it.

Run `envil -h` to see all the commands available. For instance, if you clone that repository and `cd` into your local clone,
you can run the following:

- `envil shell -d examples/statedir`: show all the envs defined in the example statedir and let you select some of these envs. Then open those envs in a subshell
- `envil switch -d examples/statedir`: select a statedir (`-d`) and several environments in this statedir, and then replace the whole stack with them.
  Registers `examples/statedir` as the current statedir.
- `envil push`: select an env to add to the top of the env stack. Globally add to your `PATH` the executables it contains
- `envil pop`: deactivate the last env added to the stack
- `envil update`: update the flake.lock files for some environments, and reload the current stack
- `envil status`: show the current statedir, the currently activated envs (with their bins), and (if any) the env activated in the current subshell

Subshells started by `envil` export the `$SHELL_ENV` environment variable. You can use it in your shell prompt (eg. `PS1` for `bash`) so it shows
which env(s) is (are) activated in the subshell. For instance if you use `bash`, add the following to your `.bashrc`:

```bash
if [[ -n "$SHELL_ENV" || "$SHLVL" > 1 ]]; then
    shell_env_bit='\e[0;33m[$SHELL_ENV($SHLVL)]\e[0m'
fi

PS1="${shell_env_bit}...the rest of your prompt..."
```

(`$SHLVL` is a standard `bash` environment variable telling you how many levels of subshells you are currently in)

## Updating `envil`

Run `nix profile upgrade envil --refresh` to update `envil` to the latest version.

## Related tools & philosophy

`envil` is related to [`devenv`](https://devenv.sh/), [`devbox`](https://www.jetify.com/docs/devbox/),
[`flox`](https://flox.dev/), [`flakey-profile`](https://github.com/lf-/flakey-profile) and
[`home-manager`](https://github.com/nix-community/home-manager) but with a focus on:

- usability by people who do not write or write little Nix code;
- compatibility with existing Nix tools, and no disruption of your existing Nix installation and configuration;
- reusable and composable environments, meaning that:
  - any env can extend (or import, include, whatever you prefer) other envs,
  - statedirs can be imported and included into one another,
  - you can have several environments activated at the same time;
- production of regular and (as much as possible) idiomatic Nix flakes that do not require `--impure`.

Also, `envil` strongly encourages decomposition. If you write Nix code, then writing small & local Nix flakes to
then reuse them in `envil` envs is perfectly encouraged. `envil` will not write complicated Nix logic for you,
just the classic boilerplate needed to define a top-level flake with some `pkgs.buildEnv` calls.

Contrary to `nix profile`, `envil` will not do anything to track versions of environments via some history. Given it represents its configuration as a simple yaml file,
therefore versioning can just be done with `git`.
