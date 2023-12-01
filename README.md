# Quick Change Directory

[![Test](https://github.com/rakus/quick_change_directory/workflows/Test/badge.svg)](https://github.com/rakus/quick_change_directory/actions?query=workflow%3ATest)

## What is Quick Change Directory?

Quick Change Directory or short "qc" is tool to quickly navigate through a
directory tree.

It creates a index file with all directories from a directory tree and
then searches this index to find the directory to change to. The creation of the
index is configurable and multiple indexes can be created.


## Searching and changing directories

Prerequisite for searching for directories is that an index is created. The
following sections contain a short outline about the required index(es). More
details can be found in the chapter [The Index](#the-index).

A search might return multiple matching directories. In this case a shell select
dialog is displayed. Like:

    $ qc test
    1) ~/code/quick-change-directory/test
    2) ~/code/parseargs/tests
    # or 'q' to quit?

If [fzf] is available and the environment variable `QC_FZF` is set, `fzf` is
used instead of the shell select command.

### Searching by Name

Searching by name requires that an index is created. This can be done by calling
`qc -u`. By default two index files are created. One containing all directories,
excluding hidden directories (and their descendants) and one containing only
hidden directories and their descendants (hidden or not).

The command `qc` can be called with one or more arguments. This arguments are
joined together to form a search string to search for matching directories.

The all arguments, except those ending with `/`, get an asterisk appended and
then the arguments are joined together with `/` characters.

So: `qc Proj` searches for `Proj*` and `qc test Proj` search for `test*/Proj*`.

As a trailing slash prevents the appending of an asterisk, the  command `qc
test/ case` searches for `test/case*` and `qc lyrics/` searches for a directory
with the exact name `lyrics`.

Additionally an argument can be prefixed with two slashes to search for a name
somewhere below the previous name.

So: `qc Proj //quick` searches for `Proj*/**/quick*`. This searches for a
directory named `quick*` one or more levels below a directory named `Proj*`.

Summary:
* `Hello World`  -> `Hello*/World*`
* `Hello/ World` -> `Hello/World*`
* `Hello/World`  -> `Hello/World*`
* `Hello/World/` -> `Hello/World`
* `Hello //World` -> `Hello*/**/World*`
* `Hello//World` -> `Hello*/**/World*`

The following wildcards can be used in the arguments. _Note that wildcard
expansion is disabled for `qc`, so no escaping is needed._

| Wildcard | Matches                                   | Regular Expression |
| -------- | ----------------------------------------- | ------------------ |
|  `*`     | Zero or more characters excluding '/'     | `[^/]*`            |
|  `?`     | A single character excluding '/'          | `[^/]`             |
|  `**`    | Zero or more characters (_including_ '/') | `.*`               |
|  `//`    | Zero or more intermediate directories     | `\(.*/\)*`         |


All searches are case-sensitive by default. Case-insensitive search can be
enabled with the option `-i` or by setting the environment variable
`QC_NO_CASE`.


#### `qc` Option for Search By Name

* `-i`  Search case-insensitive. Default when `QC_NO_CASE` is set.
* `-c`  Search case-sensitive. Default when `QC_NO_CASE` is not set.
* `-h`  Also search indexes of hidden directories.
* `-H`  Only search indexes of hidden directories.
* `-e`  Also search extended indexes.
* `-E`  Only search extended indexes.
* `-a`  Search all indexes.

BTW: If the search term given to `qc` contain a pattern that leads to a hidden
directory, the option `-h` is automatically enabled. E.g. `qc test .h case`.


### Search by Label

Searching by label requires the special "manual index". This is an index that is
manually managed by the user using the command `dstore`.  Directories can simply
be added to it or can be added with a label (aka a bookmark).

E.g. The command `dstore :test` adds the current directory to the manual index
and label it with ":test". A label always starts with a colon and may only contain
characters, digits, dash and underscore. _Labels are case-insensitive and always
stored in lower case._

A label can then be used with `qc` to change to the labeled directory.

The command `qc :test` changes to the directory labeled with `:test`.

BTW: If there is really a directory name starting with a colon _and_ it is the
first argument to `qc`, then it must be prefixed with a slash. Like: `qc /:test`

**Search by Label and Name**

It is possible to change to a sub-directory of a labeled directory like this:

    qc :qc test

This changes to the sub-directory `test` of the directory labeled as `:qc`.
The sub-directory must also be listed in an index (manual or managed).

The wildcards etc from the search by name also apply here. So `qc :label //data`
searches for a directory `data` somewhere below the directory labeled with
`:label`.

#### `qc` Option for Search By Label

With `qc -l` a list of the labeled directories are printed:

    $ qc -l
    :qc /home/rks/code/quick-change-directory
    :pa /home/rks/code/parseargs

For "Search by Label and Name" the case related options can be used:

* `-i`  Search case-insensitive. Default when `QC_NO_CASE` is set.
* `-c`  Search case-sensitive. Default when `QC_NO_CASE` is not set.


## Command Line Completion

Bash and zsh command line completion is supported for 'qc'. Just use `<TAB>` as
you would do for the cd commands.

Like:

    > qc  Documents//Y<TAB>
    > qc  Documents//YoYo/

When using bash, make sure that [bash-completion] is installed. Just execute
`declare -F "_get_comp_words_by_ref"`. If this prints the function name, it is
already installed. Else check your package manager or install it manually.


## Configuration

Qc can be configured with the following environment variables:

* `QC_DIR` - Default is `$HOME/.qc`. The directory with the index configuration
  file (`qc-index.cfg`) and the created indexes. For local installation this
  directory also contains all scripts. Important: If `qc-build-index` is run
  via crontab, make sure the correct variable is set in that context too.

* `QC_NO_CASE` - Switches qc search to case-insensitive by default. Qc acts as
  if the option `-i` is always given. With `-c` case-sensitive search can be
  forced.

* `QC_SKIP_FILTER_EXISTING` - By default qc filters out all not existing
  directories. By setting this variable this can be skipped. Useful when
  file system access is slow.

* `QC_SORT_LENGTH` - Qc sorts the results alphabetically. When this variable is
  set, the result is sorted by length (shortest first).

* `QC_FZF` - If not empty use `fzf` instead of the shells `select` to
  choose a directory on multiple matches.

* `QC_USE_FIND` - By default qc prefers `fd` to `find` to scan  the directory
  tree. By setting `QC_USE_FIND` to not empty the command `find` is used.

Note that all boolean configuration variables are enabled if they are set to any
non-empty value. E.g. `QC_FZF=false` in fact enabled fzf support, because the
variable has a non-empty value.


## The Index

The index of quick-change-directory consists of multiple indexes, or to be more
precise, multiple index files.

The "Managed Indexes" are index files that are configured and created and
updated via script.

The "Manual Index" is a file that is managed by the user using the command
`dstore`.

Some directory names cannot be handled correctly. See [Unusual Directory
Names](#unusual-directory-names),

### The Managed Indexes

The managed indexes are one or multiple index files that are configured and
created using the script `qc-build-index`. This script is either invoked via
`qc` or via a crontab entry. The script is located in `~/.qc`.

#### Configuring the Managed Index

The configuration is in the file `~/.qc/qc-index.cfg`. This files contains
definition of index files. Comment lines start with `#`. Trailing comments are
not supported. Empty lines are ignored.

Environment variables can be used in index definitions. Note, that the value of
the variable `$HOSTNAME` is automatically changed to lower case.

Quoting rules are like for the command line.

The easiest way to open the configuration file is with the command `qc
--config`.

Example entries:

    # Create normal index of $HOME that ignores all hidden directories and
    # directories named 'CVS'
    home.index $HOME -- CVS

    # Create index of $HOME only containing hidden directories.
    # Ignores some 'useless' hidden dirs.
    home.index.hidden $HOME -- .metadata .settings .git .svn .hg .bzr .cache

A line in the configuration file has the following structure:

    <index-file-name> [OPTIONS] <root-dir>... [ -- <ignore>...]

##### Index File Name

The index file name is a plain file name that follows certain rules. The content
of the index and it's usage depends on the extension. The index files are
created in `~/.qc/index`.

* `*.index` - Normal Index - Files with this extensions contains directory names
  excluding hidden directories and their descendants. Hidden files can be
  included by option (see below).<br>
  Normal index files are always searched, except when they are explicitly
  disabled with `-H` or `-E`.

* `*.index.hidden` - Hidden Index - This files contains hidden directories and
  their descendants.<br>
  Hidden index files are only searched when the option `-h`, `-H` or `-a` are
  used. They are also searched, if one the arguments to qc starts with a dot.

* `*.index.ext` - Extended Index - They are like normal index files, but are
  typically used to create an index of a directory that is rarely changed to or
  only need seldom update.<br>
  Extended index files are searched when the option `-e`, `-E` or `-a` is
  used.

_Host-Local Index Files_

All the above index file types can also be defined as being host-local. This is
useful if the home directory is shared between different machines and an index
should only be created and searched on a special host.

The name of a host-local index is like mentioned above, but with
`.host.<hostname>` appended. The host name must be given in lower case. It is
also possible to use the environment variable `$HOSTNAME` here.

E.g. The index file named `data.index.host.pluto` is only updated and searched
on a machine with the host name "pluto".


##### Options

* `-h` - Also include hidden directories and their descendants in an index that
  would normally exclude them.

* `-d depth` -  Limits the depth of the created index.<br>
    1 only includes the immediate sub-directories of the root-dir(s)<br>
    2 includes two levels of directories<br>
    ...

* `-f filter` -  Only include directories which full path match the given filter.
  The filter will contain wildcards and must be quoted.  E.g.: `-f '*/logs/*'`
  only include directories named 'logs' and their descendants.<br>
  A index with this option is always created using 'find', as it is _not
  supported_ for 'fd'.<br>
  **Note: This option is under scrutiny for removal.**

* `-I` - Only relevant if index is build with 'fd', else silently ignored.
  Don't ignore files from `.gitignore` etc. By default, fd ignores directories
  listed in several ignore files. See man page of `fd` for details.

##### Root Directories

The index is build for one or more root directories. If a root directory does
not exist, a warning is printed, but processing continues. As long as at least
one root directory exists, the index is created.

It is possible to use a environment variable here. Like `$HOME`.

##### Ignores

After a `--` a list of directory names to ignore can be given. It can be simple
names like `tmp` or path fragments like `target/classes`. If wildcards are used,
the name has to be quoted (e.g. `"tmp*"`).

The ignored directory and its descendants are excluded from the index.

#### Creating or Updating the Index Files

The index files are created and updated with the script `qc-build-index`. This
uses the tool [fd] to scan the directory tree. If `fd` is not available or the
environment variable `QC_USE_FIND` is set, the tool `find` is used. The index
files created by this tools might be different, as `fd` uses certain ignore
files (like `.gitignore`) and the handling of symbolic links is slightly
different.

The performance with `fd` is much better than with `find`.

BTW: On Debian based systems, the fd executable is called `fdfind`.

##### Updating via Command

The command `qc` can be called with the option `-u` or `-U` to update the
indexes. With `-u` normal and hidden indexes are updated, with `-U` also the
extended indexes are updated.

It is also possible to start a partial update by providing directory names. Then
only the given directories are updated and only index files containing those
directories are affected.

E.g. To updates the directory `$PWD/data` use

    qc -u data

##### Updating via Cron

It is possible to update the index via cron. The script `qc-build-index` has a
own option to manipulate the crontab. Executing `qc-build-index --cron 10` adds
a crontab entry to update the index every 10 minutes.

Example entry in the `crontab`:

    # Quick Change Directory: update index
    */10 * * * * ${HOME}/.qc/qc-build-index >${HOME}/.qc/index/qc-build-index.log 2>&1

The current cron configuration can be displayed with `qc-build-index --cron`.

See `qc-build-index --help` for other supported options.

### The Manual Index

The manual index is stored in the single file `~/.qc/index.dstore`. This file is
managed with the command `dstore`. It contains plain directory paths or labeled
directories.

Example:

    /opt/servers/apache/config
    :qc /home/rks/code/quick-change-directory

The second entry is a labeled directory with the label `qc`.

The command `dstore` can be used to add or remove entries from the manual index.

| Command              | Description                                          |
| -------------------- | ---------------------------------------------------- |
|`dstore`              | Adds the current dir to index.                       |
|`dstore dirname`      | Adds the named dir to index.                         |
|`dstore -d`           | Removes the current dir from index.                  |
|`dstore -d dirname`   | Removes the named dir from index.                    |
|`dstore :lbl`         | Adds the current dir with the label ':lbl' to index. |
|`dstore :lbl dirname` | Adds the named dir with the label ':lbl' to index.   |
|`dstore -d :lbl`      | Removes the entry labeled with ':lbl' from index.    |

Additional the option `-l` can be used to list the content of the manual index
and `-e` opens the index file in an editor.

With `-c` the manual index is cleaned up. This removes entries that are already
contained in other indexes or entries of directories that do not exist anymore.

Also see `dstore --help`.

### Information about the Existing Indexes

Just call `qc` with the option `-S`.

    > qc -S
    /home/rks/.qc/index/home.index
       Last Upd: 2021-07-30 06:40:04.780054251 +0200
       Entries:  54.266 (5.642.960 bytes)
    /home/rks/.qc/index/home.index.hidden
       Last Upd: 2021-07-30 06:40:10.237055890 +0200
       Entries:  42.004 (4.789.003 bytes)
    /home/rks/.qc/index.dstore
       Last Upd: 2021-06-11 16:44:32.358058784 +0200
       Entries:  2 (73 bytes)
       Labeled entries:  2

This only lists indexes that could be used on the current machine.  Host-local
indexes of other hosts are not shown.

### Unusual Directory Names

File names (and hence directory names) may contain a surprising range of
characters on a Unix systems. The "surprising characters" might be newlines or
just file names that contains binary data like encoding errors (e.g. a byte
sequence, that is not a valid UTF-8 character). This names are _normally_ not
intentionally chosen by the user, but are the result of some mistake or maybe of
some copy operation between systems that use different character sets to
represent file names.

Quick Change Directory is not able to find directories with those unusual names.

Directory names that contain a newline are ignored when building the index. This
means that not only the directory itself is ignored, but also the tree below
that directory.

Directories with names containing binary data (like an encoding error) are added
to the index, but they cannot be found by the `qc` tool. Sub-directories might
be found, but only if the name with invalid encoding is not part of the search
term.

Summary: Directories with unusual names cannot be found and changed to by `qc`.


## Installation

The following files are distributed:

| File                        | Description                                      | Install Location       |
| --------------------------- | ------------------------------------------------ | ---------------------- |
| `README.md`                 | The file you are just reading.                   | Not installed          |
| `INSTALL`                   | The installation script.                         | Not installed          |
| `LICENSE`                   | The MIT license.                                 | Not installed          |
| `quick_change_directory.sh` | To be sourced by the shell.                      | `~/.qc/quick_change_directory.sh` |
| `qc-backend`                | Script implementing qc functionality.            | `~/.qc/qc-backend`     |
| `dstore`                    | Script to manage the manual index.               | `~/.qc/dstore`         |
| `qc-build-index`            | Processes `qc-index.cfg` to create index files.  | `~/.qc/qc-build-index` |
| `qc-index.cfg`              | Defines indexes to create.                       | `~/.qc/qc-index.cfg`   |
| `qc_mini`                   | Minimal version of qc. See [QC Mini](#qc-mini).  | Not installed          |


### I don't want to install -- just test it

This is easy. Just clone the git repository or download the source and do:

    export QC_DIR="$PWD"
    . ./quick_change_directory.sh

This configures the current shell and makes the commands `qc` and `dstore`
available. As no index exist, `qc` will complain on first usage. Run `qc -u` to
create a default index. The index files will be stored in the sub-directory
`index`.

### Manual Installation

This describes the installation to `$HOME/.qc`. It can be installed to any other
directory, but then the environment variable `QC_DIR` must be set to that
directory.

1. Create the directory `$HOME/.qc`.

2. Copy the following files to `$HOME/.qc`:
  * `quick_change_directory.sh`
  * `qc-backend`
  * `qc-build-index`
  * `qc-index.cfg`

3. Add the following line to your `.bashrc` (or `.kshrc` or ...):

   `[ -f "$HOME/.qc/quick_change_directory.sh" ] && . "$HOME/.qc/quick_change_directory.sh"`

4. Optional: Configure crontab, so the directory index is updated every 10 minutes.
   The index update will typically just take a few seconds.

   Run `$HOME/.qc/qc-build-index --cron 10`.

   This will add the following lines to your crontab (use `crontab -l` to check):

   ```
   # Quick Change Directory: update index
   */10 * * * * ${HOME}/.qc/qc-build-index >${HOME}/.qc/index/qc-build-index.log 2>&1
   ```

   Every execution will write its output to `~/.qc/index/qc-build-index.log`.
   This log file is always overwritten, so it only contains the log of the last
   execution.

5. Now source `quick_change_directory.sh` by executing `.
   $HOME/.qc/quick_change_directory.sh` or just start a new shell.

6. Run `qc -u` to create the index files.

### Installation Script

The installation script `INSTALL` automates the steps described in the section
"Manual Installation" above. This includes the change to your local `crontab`
and updates to `.bashrc` (both can be disabled).

If the script is called without parameter it shows some help.

    $ ./INSTALL -h
    Usage: INSTALL [-nfCSh] [-t target-dir] <copy|symlink>
       -n             Just print what would be done.
       -f             force overwrite existing files
       -C             skip cron - don't configure cronjob
       -S             skip shell config - don't change bashrc
       -h             Show this help.
       -t target-dir  install to target-dir instead of ~/.qc

To copy the files install call:

    ./INSTALL copy

To create symbolic links to the files in the current directory call:

    ./INSTALL symlink

NOTE: You can add the option '-n', so the script will just print what would be
done.

If you installed it before, you will need the option '-f' to overwrite.

The file `qc-index.cfg` will always be copied, even if `symlink` is used for
install. The file is typically changed by the user. If the file is already
installed, the new version is copied to `~/.qc/qc-index.cfg.new`.

Then source `quick_change_directory.sh` by executing

    .  $HOME/.qc/quick_change_directory.sh

or just start a new shell.

Finally run `qc -u` to create the index files.

----

## QC Mini

The file `qc_mini` provides a minimal variant of `qc` and `dstore` as shell
functions. It is intended to be sourced during shell initialization.

The idea is to have a limited `qc` on some machine where one can't (or don't
want to) install the full featured quick change directory. Typically some remote
machine that are reached via ssh and where only administrative tasks are
performed. From my personal experience labeled directories are the most imported
feature in that use case.

Differences:

* Main index file is `$HOME/.dirstore`, additional indexes are  `$HOME/.dirstore-*`.
* `dstore` works with the main index file
* No automatic index creation.
* Limited expressions (`**` not supported).
* Search is always case-sensitive (even labels).
* Command line completion had little testing.
* Help for `qc` and `dstore` can be displayed with `-h`.

----

[fzf]: https://github.com/junegunn/fzf
[fd]: https://github.com/sharkdp/fd
[bash-completion]: https://github.com/scop/bash-completion

[//]:  vim:ft=markdown:et:ts=4:spelllang=en_us:spell:tw=80

