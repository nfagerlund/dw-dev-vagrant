The modules/ directory is maintained by [r10k](https://github.com/puppetlabs/r10k).

When you first check out this repository, you need to populate the modules via:

- Install r10k (it's a ruby gem, install via `gem install r10k`)
- Run r10k to fetch the modules
- Copy the `dw_dev` module into `modules`

```
$ gem install r10k
$ r10k puppetfile install
$ cp -R dw_dev modules
```

The last step is needed because r10k wants to manage the entire `modules/`
directory itself and will delete anything not in the `Puppetfile`; copying in
the directory is simpler than maintaining another git repo for it.

To update modules, repeat the last two steps (or run update.sh).

NOTE: If you are developing `dw-dev-vagrant` itself, and are running linux, you
could symlink rather than copying the `dw_dev` directory - it will prevent you
from accidentally changing the copy in `modules/` and having r10k delete your
changes.
