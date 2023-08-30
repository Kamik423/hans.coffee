---
date: 2023-08-30 21:30
---

# How to Open Sublime Text From Windows Subsystem for Linux Version 2

In my current workflow for my day-job, I frequently find myself using my preferred shell [fish](http://fishshell.com) through the Windows Subsystem for Linux version 2 – or ^wsl^ 2 – to do operations on files in the Windows file system.
One of my most common operations is that I want to open a file in my preferred editor – Sublime Text.
When just using the regular shell in any operating system, Sublime Text provides the shell command `subl` that opens Sublime Text.
I now want to open the Windows application from the Linux shell to open a file on Windows.
Microsoft even provides a `wslpath` utility that can translate a path in the ^wsl^ into a true Windows one or the other way round.
A factor that adds additional complexity to this task is `subl` having command line arguments that I might want to use:

```text
Sublime Text build 4152

Usage: subl [arguments] [files]         Edit the given files
   or: subl [arguments] [directories]   Open the given directories
   or: subl [arguments] -- [files]      Edit files that may start with '-'
   or: subl [arguments] -               Edit stdin
   or: subl [arguments] - >out          Edit stdin and write the edit to stdout

Arguments:
  --project <project>:    Load the given project
  --command <command>:    Run the given command
  -n or --new-window:     Open a new window
  --launch-or-new-window: Only open a new window if the application is open
  -a or --add:            Add folders to the current window
  -w or --wait:           Wait for the files to be closed before returning
  -b or --background:     Don't activate the application
  -s or --stay:           Keep the application activated after closing the file
  --safe-mode:            Launch using a sandboxed (clean) environment
  -h or --help:           Show help (this message) and exit
  -v or --version:        Show version and exit

--wait is implied if reading from stdin. Use --stay to not switch back
to the terminal when a file is closed (only relevant if waiting for a file).

Filenames may be given a :line or :line:column suffix to open at a specific
location.
```

I especially care about the `--wait` flag, since this enables me to use Sublime Text as an editor, for example for setting git commit messages.
Additionally it needs to be considered that if the `--help` flag is used, usually no path is added as argument.

I then whipped up this quick Python script.
It passes on arguments that look like flags (starting with a `-`) to Windows’ `subl` and assumes that any other one is a path and translates it to a Windows one.

```python
#!/usr/bin/env python3

import subprocess
import sys

# The path to the Sublime Text Windows executable in the Linxu file-system.
SUBL = "/mnt/c/Program Files/Sublime Text/subl.exe"


def window_path(path: str) -> str:
    # Convert a Linux path to a Windows one so Sublime Text understands it.
    result = subprocess.run(f'wslpath -aw "{path}"', shell=True, capture_output=True)
    if result.stderr:
        raise subprocess.CalledProcessError(
            returncode=result.returncode, cmd=result.args, stderr=result.stderr
        )
    # Somehow `subl` only understands paths using slashes instead of backslashes
    # as you would expect from a Windows command line utility. So we replace all
    # of the backslashes with regular slashes. Afterwards spaces in the path are
    # escaped so `subl` understands any path as a single argument, not multiple.
    return result.stdout.decode("utf8").strip().replace("\\", "/").replace(" ", "\\ ")


def main() -> int:
    # Execute the command on the Linux command line. Any argument beginning with
    # a `-` is passed on directly to `subl` (like `-w` or `--help`). However any
    # other argument is converted to a Windows path from a Linux one.
    command = f'exec "{SUBL}" ' + " ".join(
        [arg if arg.startswith("-") else f"{window_path(arg)}" for arg in sys.argv[1:]]
    )
    process = subprocess.Popen(
        command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True
    )
    # Print any output of `subl` like help text or errors.
    print(process.communicate()[0].decode("utf8"), end="", flush=True)
    return process.returncode


if __name__ == "__main__":
    # Pass through the return code
    sys.exit(main())
```

I placed this file in ^wsl^’s `/usr/local/bin/` directory, named it `subl` (without any extension) and marked it as executable using

```sh
sudo chmod a+x subl
```

Linux knows to execute this file with Python 3 since it starts with the [shebang line](https://en.wikipedia.org/wiki/Shebang_%28Unix%29) marking it as such.
The utility passes on the exit code of `subl.exe` to ^wsl^.
Any paths on the Windows side of the ^vm^ divide are easily understood.
Paths that refer to files or directories on the Linux side use `\\wsl.localhost\Debian\` as the root directory.
This mounts the ^wsl^ 2 file system on Windows.

As a result this means that even temporary files on the Linux side, like git commit messages can be edited.
You can even use fish’s `funced` command to edit functions with Sublime Text.
to simplify the process, I set my `$EDITOR` environment variable to `sublw` which refers to another little script I put in the `/usr/local/bin` directory:

```bash
#!/bin/bash
subl -w $1
```

This uses the `-w` or `--wait` flag to only exit from the call once Sublime Text is closed again, i.e., after a user has edited and saved the file.
Without this flag, the `subl` command would immediately return once the file is *opened* in Sublime Text.

With the `subl` and potentially the `sublw` utility you can now easily use Sublime Text on Windows from the Windows Subsystem for Linux.
You should be able to just copy the code above or copy it from [this GitHub gist](https://gist.github.com/Kamik423/80ebcef8d0308aa80307291394b19f5d).