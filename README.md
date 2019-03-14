# Quick Change Directory


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
    qc 'YoYo/*/Admin'       # '*' matches on subdirs
    qc 'Customer/**/Admin'  # '**' matches multiple subdirs
    qc YoYo '*' Admin
    qc Cust '**' Admin

### Command line completion

Bash command line completion is supported for 'qc'. Just use <TAB> as you
would do for the cd commands.

Like:

    > qc  Documents//Y<TAB>
    > qc  Documents//YoYo/

### Other qc option:

* `-i` Search is case-insensitive (and slower). Only when searching by name.
* `-e` Also search extended index files.
* `-u` Update the normal indexes.
* `-U` Update the normal and extended indexes.
* `-l` List labeled directories.
* `-S` Print statistics of index files.
* `--help` Shows help.

Note:
* calling `qc` without parameter acts like calling `cd` without parameter
* calling `qc -` acts like calling `cd -`


## Indexes

The qc universe knows three type of indexes. Two of those types can be created
automatically (via script), the third one is for manual management.

All index files are held in the directory `~/.qc`.

### Normal and Extended Indexes

This indexes are normal text files with one directory name per line.

Normal indexes have the file extension `.index` and are always searched by qc.

Extended indexes have the file extension `.index.ext` and are only searched when
qc is called with the option `-e`.

The indexes are defined in the file `~/.qc/qc-index.list`.

Example:

    home.index $HOME -- '.*' CVS

This defines the index "home.index" (file: `~/.qc/home.index`), that contains
all directories below `$HOME`, but excludes `.*` (= hidden dirs) and directories
named `CVS`.

The comments in the file `qc-index.list` contains more details and examples.

The file `qc-index.list` is processed using the script `qc-build-index.sh`.

**Update Performance**

My home directory contains ~100000 directories and my HD is a SSD.
I have two indexes defined (see file qc-index.list).

After dropping the file caches the first update takes about 20-30 seconds.
Subsequent updates are much faster, they take about 3 seconds.

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

| File                | Description                                            | Install Location          |
| ------------------- | ------------------------------------------------------ | ------------------------- |
| `README.md`         | The file you are just reading.                         | Not installed             |
| `INSTALL.sh`        | The installation script.                               | Not installed             |
| `_quick_change_dir` | The script to be sourced by .bashrc (or .kshrc).       | `~/.quick_change_dir`     |
| `qc-build-index.sh` | Processes `qc-index.list` to create index files.       | `~/.qc/qc-build-index.sh` |
| `qc-index-proc.sh`  | Called by `qc-build-index.sh` to creates a index file. | `~/.qc/qc-index-proc.sh`  |
| `qc-index.list`     | Defines indexes to create.                             | `~/.qc/qc-index.list`     |


### I don't want to install -- just test it

This is easy. Just do:

    . ./_quick_change_dir

As no index exist, this will create the directory `~/.qc` and create a default
index of all directories in your home directory (excluding hidden dirs).

### Manual Installation

1. Create the directory `$HOME/.qc`.

2. Copy the following files to `$HOME/.qc`:
  * `qc-build-index.sh`
  * `qc-index-proc.sh`
  * `qc-index.list`

3. Copy `_quick_change_dir` to `$HOME/.quick_change_dir`. Note the leading dot!

4. Add the following line to your `.bashrc` (or `.kshrc`):

   `[ -e "$HOME/.quick_change_dir" ] && . $HOME/.quick_change_dir`

5. Optional: Extend your local crontab, so the directory index is updated every 10 minutes.
   The update will typically just take a few seconds (on my machine with SSD).

   Run `crontab -e` and add the following line at the end of the file:

   `*/10 * * * * ${HOME}/.qc/qc-build-index.sh >${HOME}/.qc/qc-build-index.log 2>&1`

   Every execution will write its output to `~/.qc/qc-build-index.log`. This log file
   is always overwritten, so it only contains the log of the last execution.

6. Now source `.quick_change_dir` by executing `. $HOME/.quick_change_dir` or just start a new shell.
   During the first sourcing of the script, the indexes are created.

### Installation Script

The installation script `INSTALL.sh` automates the steps described in the
section "Manual Installation" above. This includes the change to your local
crontab and updates to .bashrc and .kshrc (if available).

If the script is called without parameter, it will run in "simulation mode" and
only print what would be done.

To really run the installation execute `./INSTALL.sh YES`.

Then source `.quick_change_dir` by executing `. $HOME/.quick_change_dir` or
just start a new shell.
During the first sourcing of the script, the indexes are created.


## Portability

### ksh93

Should(!) run unchanged. The script `.quick_change_dir` and the supporting
scripts `qc-build-index.sh` and `qc-index-proc.sh` were briefly tested with
ksh93 version "93u+ 2012-08-01".

Needs further testing.

### zsh

Running `.quick_change_dir` with zsh needs some porting:

* zsh arrays are 1-based while bash/ksh uses 0-based arrays
* In the context of `getopt`, shifting by `OPTIND` seems different.
* Some language constructs used in bash/ksh do not work as expected. Like
  `${@:2}`.


[//]:  vim:ft=markdown:et:ts=4:spelllang=en_us:spell:tw=80

