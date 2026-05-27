```
                                 (                            
   (                             )\ )                       ) 
   )\   (      (     )       )  (()/(     (   (          ( /( 
 (((_)  )(    ))\   (     ( /(   /(_)) (  )(  )\  `  )   )\())
 )\___ (()\  /((_)  )\  ' )(_)) (_))   )\(()\((_) /(/(  (_))/ 
((/ __| ((_)(_))  _((_)) ((_)_  / __| ((_)((_)(_)((_)_\ | |_  
 | (__ | '_|/ -_)| '  \()/ _` | \__ \/ _|| '_|| || '_ \)|  _| 
  \___||_|  \___||_|_|_| \__,_| |___/\__||_|  |_|| .__/  \__| 
                                                 |_|          
```

Copyright (c) 2024-2026 Bruno Crema Ferreira
OpenSource - MIT License             

# Crema Script

A collection of Bash utility scripts for Python development environments. Designed to streamline virtual environment management, dependency control, packaging, and Jupyter Notebook integration across Linux, macOS, and BSD systems.

## Requirements

- Bash or Zsh shell
- Python 3
- `pip`
- `zip` (for `devpack`)
- Jupyter (optional, installed on demand by `jup`)

## Installation

Run `devstart` directly (without `source`) once to register it in your shell's PATH:

```bash
bash /path/to/crema-script/python/devtools/bin/devstart
```

This will:
- Add the `bin/` directory to your shell's RC file (`.bashrc`, `.bash_profile`, or `.zshrc`)
- Copy the `.env` configuration to `~/.env-crema-script`

Restart your terminal session after installation.

## Configuration

The `.env` file (copied to `~/.env-crema-script`) holds environment variables used by the scripts:

| Variable            | Default            | Description                              |
|---------------------|--------------------|------------------------------------------|
| `PACKAGES_DIRECTORY`| `~/packages`       | Output directory for `devpack` zip files |

## Usage

Navigate to your Python project directory (which must contain a `requirements.txt`) and source the script:

```bash
source devstart
```

### Commands

| Command                   | Description                                                                      |
|---------------------------|----------------------------------------------------------------------------------|
| `source devstart`         | Activate venv (creates if not exists) and install requirements                   |
| `source devstart -f`      | Recreate `.venv` from scratch and install requirements                           |
| `source devstart -v X.Y`  | Create/activate venv using Python X.Y; auto-recreates if version differs         |
| `devstop`                 | Deactivate the dev environment and restore the original prompt                   |
| `devclean`                | Remove all `*.pyc` files and `__pycache__` directories                           |
| `devpack`                 | Export the current project as a timestamped `.zip` file                          |
| `devreq`                  | Pin all packages in `requirements.txt` to their installed versions               |
| `jup`                     | Install (if needed) and launch Jupyter Notebook in the active venv               |
| `devhelp`                 | Show the help menu                                                               |

### Python Version Selection

Pass `-v X.Y` to pin the venv to a specific Python version:

```bash
source devstart -v 3.12
```

- If no venv exists, it is created with `python3.12`.
- If a venv already exists with a **different** Python version, it is automatically recreated.
- If a venv already exists with the **same** version, it is activated as-is.
- Combine with `-f` to force a full recreate regardless: `source devstart -f -v 3.12`.

### PS1 Prompt

While `devstart` is active, the shell prompt is prefixed with the current git branch:

```
devstart[main]->$
```

## Project Structure

```
crema-script/
└── python/
    └── devtools/
        ├── bin/
        │   └── devstart      # Main script — sources lib.sh and drives the workflow
        ├── lib/
        │   └── lib.sh        # Shared utility functions (log, die, checkDependency, etc.)
        └── .env              # Environment variable defaults
```

### `lib.sh` Utilities

`lib.sh` exposes general-purpose helpers that can be reused in other scripts:

- `log <message> <mode> [version]` — Colored output; modes: `intro`, `title`, `success`, `information`, `warning`, `error`
- `die <message> <exitCode>` — Print error and abort
- `checkDependency <cmd> <name>` — Verify a command is available on PATH
- `checkIfIsRoot` — Assert the script is running as root
- `startContainer <name>` — Start a Docker container if not already running
- `stopContainer <name>` — Stop a running Docker container

## License

MIT License — see [LICENSE](LICENSE)
