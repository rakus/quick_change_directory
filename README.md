# Quick Change Directory

[![Test](https://github.com/rakus/quick_change_directory/workflows/Test/badge.svg)](https://github.com/rakus/quick_change_directory/actions?query=workflow%3ATest)

## What is Quick Change Directory?

Quick Change Directory or short "qc" is tool to quickly navigate through a
directory tree.

It creates a index file with all directories from a directory tree and
then searches this index to find the directory to change to. The creation of the
index is configurable and multiple indexes can be created.

## Searching and changing directories

### Search by (part of the) directory name

Example: `qc Pro`

This searches for a directory named `Pro*`. It would match something like:

    ~/Documents/Customer/Project
    ~/Documents/Customer/YoYo/Protocols
    ~/Documents/private/Profile

If only one name matches, the directory is changed immediately.
If multiple entries matches, a list of possible target directories is
displayed. Choose one by number and the directory is changed or enter `q`
to quit.

    ~ > qc Pro
    1) ~/Documents/Customer/Project
    2) ~/Documents/Customer/YoYo/Protocols
    3) ~/Documents/private/Profile
    #?

Example: `qc Project/Ser`

This searches for a directory path that ends with `.../Project/Ser*`. It would
match something like:

    ~/Documents/Customer/Project/Server
    ~/Documents/Customer/Project/Serial


Example: `qc Project/Ser/`

This searches for a directory path that ends with `.../Project/Ser`. Note, that
there is no wildcard at the end.


Example: `qc Documents//Cust`

This searches for a directory named `Cust*` somewhere below a directory named
`Documents`.

    .../Documents/Customer
    .../Documents/Test/Customer
    .../Documents/Stuff/YoYo/Test/Customer


### Search with multiple parameters

Example: `qc Project Ser`

This searches for directory path that ends with `.../Project*/Ser*`
It would match something like:

    ~/Documents/Customer/Project/Server
    ~/Documents/Customer/Project/Serial
    ~/Documents/Customer/Project-Test/Server

Note: Trailing '/' prevents appending wildcards.  So:

    qc Project/ Ser

is equivalent to

    qc Project/Ser

### Search by label

Example: `qc :apachelog`

This searches for a entry that is labeled with ":apachelog".

Qc works with an additional command named `dstore` (like "directory store") that
is able to create a label (aka  bookmark) for a directory.

Dstore and labels are explained in the section [Manual Index](#manual-index).

### Details on Expression

The expression is case-sensitive. Use `qc -i ...` to switch to case-insensitive
matching.

Every parameter, that does not end with a `/` gets a `*` appended before it
is joined with the next word with a `/`.
So:
* `Hello World`  -> `Hello*/World*`
* `Hello/ World` -> `Hello/World*`
* `Hello/World`  -> `Hello/World*`
* `Hello/World/` -> `Hello/World`

Supported Wildcards:

|Wildcard| Matches                                 | Regular Expression |
| ------ | --------------------------------------- | ------------------ |
| `*`    | Zero or more characters excluding '/'   | `[^/]*`            |
| `?`    | A single character excluding '/'        | `[^/]`             |
| `**`   | Zero or more characters (including '/') | `.*`               |
| `//`   | Zero or more intermediate directories   | `\(.*/\)*`         |

Note: More than two consecutive `*` are handled as `**`. The same is true for
`/`. So:
* `***`    is equivalent to `**`
* `*****`  is equivalent to `**`
* `/////`  is equivalent to `//`

BTW: If a directory name contains non-text bytes, qc can't find this
directory. This is due to the way `grep` handles binary data.

### Multiple ways

Assume you have a directory

    ~/Documents/Customer/YoYo/MyProject/Admin

Examples to change to that directory:

    qc C Y M A
    qc MyPr Adm
    qc MyProject/Ad
    qc Customer//Admin      # "Admin" somewhere below "Customer"
    qc YoYo/*/Admin         # '*' matches on subdirs
    qc Customer/**/Admin    # '**' matches multiple subdirs
    qc YoYo * Admin
    qc Cust ** Admin

Note that wildcard expansion is disabled for `qc`. No need to escape `*` etc.

### Command line completion

Bash command line completion is supported for 'qc'. Just use <TAB> as you
would do for the cd commands.

Like:

    > qc  Documents//Y<TAB>
    > qc  Documents//YoYo/

### Other qc option:

* `-i` Search is case-insensitive. Only when searching by name.
* `-h` Also search index files of hidden directories.
* `-H` Only search index files of hidden directories.
* `-e` Also search extended index files.
* `-E` Only search extended index files.
* `-a` Search all index files.
* `-u` Update the normal & hidden indexes.
* `-U` Update the normal, hidden and extended indexes.
* `-l` List labeled directories.
* `-S` Print statistics of index files.
* `--help` Shows help.

Note:
* calling `qc` without parameter acts like calling `cd` without parameter
* calling `qc -` acts like calling `cd -`

## Configuration

Qc can be configured with the following environment variables:

* `QC_DIR` - Default is `$HOME/.qc`. The directory with the index configuration
  file (`qc-index.cfg`) and the created indexes. For local installation this
  directory also contains all scripts. Important: If `qc-build-index` is run
  via crontab, make sure the correct variable is set in that context too.

* `QC_SKIP_FILTER_EXISTING` - By default qc filters out all not existing
  directories. By setting this variable this can be skipped. Useful when
  file system access is slow.

* `QC_SORT_LENGTH` - Qc sorts the results alphabetically. When this variable is
  set, the result is sorted by length (shortest first).

* `QC_FZF` - On multiple matches use `fzf` instead of the shells `select` to
  choose a directory.

## Indexes

The qc universe knows four type of indexes. Three of those types can be created
automatically (via script), the fourth one is for manual management.

All index files are held in the directory `~/.qc` (or whatever `QC_DIR` is set
to).

### Normal, Hidden and Extended Indexes

This indexes are normal text files with one directory name per line.

Normal indexes have the file extension `.index` and are searched by qc by
default.

Hidden indexes have the file extension `.index.hidden` and only contain
hidden directories and their descendants. They are searched when the options
`-h`, `-H` or `-a` are given

Extended indexes have the file extension `.index.ext` and are only searched when
qc is called with the option `-e`, `-E` or `-a`.

The indexes are defined in the file `~/.qc/qc-index.cfg`.

Example:

    home.index $HOME -- CVS
    home.index.hidden $HOME -- .git .cache
    dev.index.extended /opt/dev

This defines three indexes:
* `home.index` (file: `~/.qc/home.index`) contains all directories below
  `$HOME` excluding hidden dirs. It also excludes directories named `CVS`.
* `home.index.hidden` (file: `~/.qc/home.index.hidden`) contains all hidden
  directories and their descendants below `$HOME`, but excludes `.git` and
  `.cache`.
* `dev.index.ext` (file: `~/.qc/dev.index.ext`) contains all directories below
  `/opt/dev` excluding hidden directories.

The comments in the file `qc-index.cfg` contains more details and examples.

The file `qc-index.cfg` is processed using the script `qc-build-index`.

__Host-Local Indexes__

Sometimes the home directory of a user is used on different host. Then also the
QC configuration is shared. If a index should only be used on a special host,
the index name can get the hosts name as extension. The host name **must be
written in UPPER case**.

Examples (assuming hosts "pluto" and "mars"):

    dev.index.PLUTO
    dev.index.ext.PLUTO
    dev.index.MARS
    dev.index.ext.MARS

BTW: If the variable $HOSTNAME is used:

    dev.index.$HOSTNAME

The script `qc-build-index` sets the host name in upper case.


__Update Performance__

My home directory contains ~170000 directories and my HD is a SSD.
I have two indexes defined (see file qc-index.cfg).

After dropping the file caches the first update takes about 55 seconds.
Subsequent updates are much faster due to caching, they take about 10 seconds.

Update performance depends on the number of indexes and their definition.

BTW: Due to ignored dirs (like .git, .metadata, ...) only about 95000
directories are stored in the indexes.

### Manual Index

The manual index is stored in the file `~/.qc/index.dstore`. It is used by qc
during normal searches and while searching for labeled directories.

The file contains two types of entries (lines):

1. Normal entries, that are just a directory name. (Like for the previous
   indexes.)
2. Labeled entries, where the directory name is prefixed with a label.

Example:

    /opt/servers/apache/config
    :qc /home/joedoe/tools/quick_change_directory

The content of `index.dstore` is managed with the command `dstore`.

| Command              | Description                                          |
| -------------------- | ---------------------------------------------------- |
|`dstore`              | Adds the current dir to index.                       |
|`dstore dirname`      | Adds the named dir to index.                         |
|`dstore -d`           | Removes the current dir from index.                  |
|`dstore -d dirname`   | Removes the named dir from index.                    |
|`dstore :lbl`         | Adds the current dir with the label ':lbl' to index. |
|`dstore :lbl dirname` | Adds the named dir with the label ':lbl' to index.   |
|`dstore -d :lbl`      | Removes the entry labeled with ':lbl' from index.    |

Other usage of `dstore`:

| Command        | Description                                    |
| -------------- | ---------------------------------------------- |
|`dstore --help` | Shows help.                                    |
|`dstore -l`     | Lists content.                                 |
|`dstore -e`     | Opens `index.dstore` in a editor (default vi). |
|`dstore -c`     | Cleans up by removing none-existing or duplicate entries or entries already contained in another index file. It also warns about duplicate labels. |

The editor used for `dstore -e` is either the value of `$VISUAL` or the value
of `$EDITOR` or defaults to `vi`.

### Information about the existing indexes

Just call `qc` with the option `-S`.

    > qc -S
    /home/rks/.qc/home.index
       Last Upd: 2021-07-30 06:40:04.780054251 +0200
       Entries:  54.266 (5.642.960 bytes)
    /home/rks/.qc/home.index.hidden
       Last Upd: 2021-07-30 06:40:10.237055890 +0200
       Entries:  42.004 (4.789.003 bytes)
    /home/rks/.qc/index.dstore
       Last Upd: 2021-06-11 16:44:32.358058784 +0200
       Entries:  2 (73 bytes)
       Labeled entries:  2

This only lists indexes that could be used on the current machine.  Host-local
indexes of other hosts are not shown.


## QC Mini

The file `qc_mini` provides a minimal variant of `qc` and `dstore` as shell
functions. It is intended to be sourced during shell initialization.

The idea is to have a limited `qc` on some machine where one can't (or don't
want to) install the full featured quick change directory. Typically some remote
machine that are reached via ssh and where only administrative tasks are
performed. From my personal experience labeled directories are the most imported
feature in that use case.

Restrictions:

* Only one index file (`$HOME/.dirstore`) used for normal and labeled entries
* No automatic index creation.
* Limited expressions (`**` and `?` not supported)


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


### I don't want to install -- just test it

This is easy. Just do:

    export PATH="$PATH:$PWD"
    . ./quick_change_directory.sh

As no index exist, `qc` will complain on first usage. Run `qc -u` to create a
default index of all directories in your home directory (excluding hidden dirs).

### Manual Installation

1. Create the directory `$HOME/.qc`.

2. Copy the following files to `$HOME/.qc`:
  * `quick_change_directory.sh`
  * `qc-backend`
  * `qc-build-index`
  * `qc-index.cfg`

3. Add the following line to your `.bashrc`:

   `[ -f "$HOME/.qc/quick_change_directory.sh" ] && . "$HOME/.qc/quick_change_directory.sh"`

4. Optional: Configure crontab, so the directory index is updated every 10 minutes.
   The index update will typically just take a few seconds.

   Run `$HOME/.qc/qc-build-index --cron 10`.

   This will add the following lines to your crontab (use `crontab -l` to check):

   ```
   # Quick Change Directory: update index
   */10 * * * * ${HOME}/.qc/qc-build-index >${HOME}/.qc/qc-build-index.log 2>&1
   ```

   Every execution will write its output to `~/.qc/qc-build-index.log`. This log file
   is always overwritten, so it only contains the log of the last execution.

5. Now source `quick_change_directory.sh` by executing `.
   $HOME/.qc/quick_change_directory.sh` or just start a new shell.

6. Run `qc -U` to create the index files.

### Installation Script

The installation script `INSTALL` automates the steps described in the
section "Manual Installation" above. This includes the change to your local
crontab and updates to .bashrc.

If the script is called with out parameter it shows some help.

To copy the files install call:

    ./INSTALL copy

To create symbolic links to the files in the current directory call:

    ./INSTALL symlink

NOTE: You can add the option '-n', so the script will just print what would be
done.

If you installed it before, you will need either '-f' (to overwrite) or '-b' (to
create backup files using the current time stamp).

The file `qc-index.cfg` will always be copied. Even if `symlink` is used for
install. The file is typically changed by the user. If the file is already
installed, the new version is copied to `~/.qc/qc-index.cfg.new`.

Then source `quick_change_directory.sh` by executing

    .  $HOME/.qc/quick_change_directory.sh

or just start a new shell.

Finally run `qc -U` to create the index files.


[//]:  vim:ft=markdown:et:ts=4:spelllang=en_us:spell:tw=80

