# Prezto-wam

Defines personal aliases for zsh shell. Package as a [Prezto][1] Module.

## Installation

By default prezto modules will be loaded from _`/modules`_ and _`/contrib`_.

Additional module directories can be added to the `:prezto:load:pmodule-dirs` setting in _`${ZDOTDIR:-$HOME}/.zpreztorc`_.
Note that module names need to be unique or they will cause an error when loading.

```sh
zstyle ':prezto:load' pmodule-dirs $HOME/.zprezto-contrib
```

Clone this repository to the .zprezto-contrib location.

Add `'prezto-wam'` to the `pmodule` list (under `zstyle ':prezto:load' pmodule \` in your
_`${ZDOTDIR:-$HOME}/.zpreztorc`_) to enable this module.

## Aliases

- `vpn-connect` start OpenVPN3 custom session and use pass-cli for credentials.
- `vpn-disconnecy` stop current OpenVPN3 session.
- `vpn-status` display active VPN sessions.

## License

This project is licensed under the MIT License.

[1]: https://github.com/sorin-ionescu/prezto
