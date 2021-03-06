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
* `-e` Also search extended index files.
* `-E` Only search extended index files.
* `-u` Update the normal indexes.
* `-U` Update the normal and extended indexes.
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
  set, the result is sorted by length (shortest first). Requires Perl.

## Indexes

The qc universe knows three type of indexes. Two of those types can be created
automatically (via script), the third one is for manual management.

All index files are held in the directory `~/.qc` (or whatever `QC_DIR` is set
to).

### Normal and Extended Indexes

This indexes are normal text files with one directory name per line.

Normal indexes have the file extension `.index` and are always searched by qc.

Extended indexes have the file extension `.index.ext` and are only searched when
qc is called with the option `-e` or `-E`.

The indexes are defined in the file `~/.qc/qc-index.cfg`.

Example:

    home.index $HOME -- '.*' CVS

This defines the index "home.index" (file: `~/.qc/home.index`), that contains
all directories below `$HOME`, but excludes `.*` (= hidden dirs) and directories
named `CVS`.

The comments in the file `qc-index.cfg` contains more details and examples.

The file `qc-index.cfg` is processed using the script `qc-build-index`.

__Host-Local Indexes__

Sometimes the home directory of a user is used on different host. Then also the
QC configuration is shared. If a index should only be used on a special host,
the index name can get the hosts name as extension.

Examples (assuming hosts "pluto" and "mars"):

    dev.index.pluto
    dev.index.ext.pluto
    dev.index.mars
    dev.index.ext.mars


__Update Performance__

My home directory contains ~140000 directories and my HD is a SSD.
I have two indexes defined (see file qc-index.cfg).

After dropping the file caches the first update takes about 30-40 seconds.
Subsequent updates are much faster, they take about 5 seconds.

Update performance depends on the number of indexes and their definition.

BTW: Due to ignored dirs (like .git, .metadata, ...) only half of the existing
directories are stored in the indexes.

### Manual Index

The manual index is stored in the file `~/.qc/index.dstore`. It is used by qc
during normal searches and while searching for labeled directories.

The file contains two types of entries (lines):

1. Normal entries, that are just a directory name. (Like for the previous
   indexes.)
2. Labeled entries, where the directory name is prefixed with a label.

Example:

    /opt/IBM/WebSphere/AppServer/profiles
    :tsmlog /var/log/tsm

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
       Last Upd: 2018-09-30 09:10:03.057322543 +0200
       Entries:  36.401 (3.857.193 bytes)
    /home/rks/.qc/home.hidden.index.ext
       Last Upd: 2018-09-30 09:10:05.165314319 +0200
       Entries:  18.171 (1.503.203 bytes)
    /home/rks/.qc/index.dstore
       Last Upd: 2018-09-30 09:01:35.034456049 +0200
       Entries:  10 (302 bytes)
       Labeled entries:  8


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

