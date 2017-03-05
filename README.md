# Quick Change Directory


## What is Quick Change Directory?

Quick Change Directory or short "qc" is tool to quickly navigate through a
directory tree.

The base of this is a index file of the entire directory tree.
Qc then searches this index to find the directory to change to.

Qc supports three ways to search for a directory to change to.

### Search by (part of the) directory name

Example: `qc Pro`

This searches for a directory named `Pro*`. It would match something like:

    ~/Documents/Customer/Project
    ~/Documents/Customer/YoYo/Protocols
    ~/Documents/private/Profile

If only one name matches, the directory is changed to that dir.
If multiple entries matches, a list of possible target directories is
displayed. Choose one by number and the directory is changed.

Example: `qc Project/ser`

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

See [Manual Index](#manual-index)


### Multiple matches

If multiple directories matches, a selection list is displayed:

    $ qc Admin
    1) /home/john/Documents/Customer/YoYo/Admin
    2) /home/john/Documents/Customer/ACME/Project1/Admin
    3) /home/john/Documents/Customer/ACME/Project2/Admin
    4) /home/john/Documents/shared/Servers/Admin
    #?

Select the directory to change to by number. Enter 'q' to abort.


### Details on Expression

1. The expression is case-sensitive. Use qc -i ... to switch to
   case-insensitive matching.

2. The character '+' is equivalent to '*'. The '+' doesn't need escaping on
   the command line.

3. Every word, that does not end with a '/' gets a '*' appended before it is
   joined with the next word with a '/'.
   So:
   * `Hallo World`  -> `Hallo*/World*`
   * `Hallo/ World` -> `Hallo/World*`
   * `Hallo/World`  -> `Hallo/World*`
   * `Hallo/World/` -> `Hallo/World`

4) The single wildcard '*' matches all but a '/'.

5) The wildcard combination '**/' matches zero or more directory names.
   So: `Hello/**/World`  matches `Hello/World`, `Hello/my/World`,
   `Hello/small/blue/World` ...

6) A double slash ('//') is equivalent to '/**/'.

7) A double asterisk _not_ followd by '/' matches zero or more characters
   (including '/')

Note: More than two consecutive '*' are handled as '**'. The same is true for
'/'. So:
* `***`    is equivalent to `**`
* `*****`  is equivalent to `**`
* `/////`  is equivalent to `//`


### Command line completion

Bash command line completion is supported for 'qc'. Just use <TAB> as you
would do for the cd commands.

### Multiple ways

Assume you have a directory

    ~/Documents/Customer/YoYo/MyProject/Admin

Examples to change to that directory:

    qc C Y M A
    qc MyPr Adm
    qc MyProject/Ad
    qc Customer//Admin    # "Admin" somewhere below "Customer"
    qc YoYo/+/Admin       # '+' matches on subdirs
    qc Customer/++/Admin  # '++' matches multiple subdirs
    qc YoYo + Admin
    qc Cust ++ Admin

### Other qc option:

* `-i` Search is case-insensitive (and slower). Only when searching by name.
* `-e` Also search extended index files.
* `-u` Update the indexes.
* `-l` List labeled directories.
* `-S` Print statistics of index files

Note:
* calling 'qc' without parameter acts like calling 'cd' without parameter
* calling 'qc -' acts like calling 'cd -'


## Indexes

The qc universe knows three type of indexes. Two of those types can be created
automatically (via script), the third one is for manual management.

All index files are held in the directory `~/.qc`.

### Normal and Extension Indexes

This indexes are normal text files with one directory name per line. 

Normal indexes have the file extension `.index` and are always searched by qc.

Extension indexes have the file extension `.index.ext` and are only searched when
qc is called with the option `-e`.

The indexes are defined in the file `~/.qc/qc-index.list`. 

Example:

    home.index $HOME -- '.*' CVS

This defines the index "home.index" (file: `~/.qc/home.index`), that contains
all directories below `$HOME`, but excludes `.*` (= hidden dirs) and directories
named `CVS`.

The file `qc-index.list` is processed using the script `qc-build-index.sh`.

### Manual Index

The manual index is stored in the file `~/.qc/index.dstore`. It is used by qc
during normal searches and while searching for labeled directories.

The file contains two types of entries (lines):

1. Normal entries, that are just a directory name. (Like for the previous
   indexes.)
2. Labeled entries, where the directory name is prefixed with a label.

The content of `index.dstore` is handled by the command `dstore`.

| Command | Description |
| --- | --- |
|`dstore` | Adds the current dir to index. |
|`dstore dirname` | Adds the named dir to index. |
|`dstore -d` | Removes the current dir from index. |
|`dstore -d dirname` | Removes the named dir from index.. |
|`dstore :lbl` | Adds the current dir with the label ':lbl' to index. |
|`dstore :lbl dirname` | Adds the named dir with the label ':lbl' to index. |
|`dstore -d :lbl` | Removes the entry labeled with ':lbl' from index. |

Other usage of `dstore`:

| Command | Description |
| --- | --- |
|`dstore --help` | Shows help. |
|`dstore -l` | Lists content. |
|`dstore -e` | Opens `index.dstore` in a editor (default vi) |
|`dstore -c` | Cleans up by removing none-existing or duplicate entries or entries already contained in another index file. It also warns about duplicate labels. |


## Installation

The following files are distributed:

| File | Description | Install Location |
| ---- | ----------- | ---------------- |
| `README.md' | The file you are just reading. | Not installed |
| `INSTALL.sh' | The installation script. | Not installed |
| `_quick_change_dir' | The script to be sourced by .bashrc. | `~/.quick_change_dir` |
| `qc-build-index.sh' | Processes `qc-index.list` to create index files. | `~/.qc/qc-build-index.sh` |
| `qc-index-proc.sh' | Creates a single index file. | `~/.qc/qc-index-proc.sh` |
| `qc-index.list' | Defines indexes to create. | `~/.qc/qc-index.list` |


### I don't want to install -- just test it

This is easy. Just do:

    . ./_quick_change_dir

As no index exist, this will create the directory `~/.qc` and create a index of
all directories in your home directory (excluding hidden dirs). 

### Manual Installation

1. Create the directory `$HOME/.qc`.

2. Copy the following files to `$HOME/.qc`:
  * `qc-build-index.sh`
  * `qc-index-proc.sh`
  * `qc-index.list`

3. Copy `_quick_change_dir` to `$HOME/.quick_change_dir`. Note the leading dot!

4. Add the following line to your `.bashrc`:

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
crontab.

If the script is called without parameter, it will run in "simulation mode" and
only print what would be done.

To really run the installation execute `./INSTALL.sh YES`.

Then source `.quick_change_dir` by executing `. $HOME/.quick_change_dir` or
just start a new shell.
During the first sourcing of the script, the indexes are created. 


## Portability

### ksh93

Should(!) run unchanged. Needs testing.

### ksh88

Unknown.

### zsh

Some code has to be adjusted. Search for "ZSH" in `_quick_change_dir`.

[//]:  vim:ft=markdown:et:ts=4:spelllang=en_us:spell:tw=80

