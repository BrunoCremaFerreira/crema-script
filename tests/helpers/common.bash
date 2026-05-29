#!/usr/bin/env bash

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEVTOOLS_DIR="$REPO_ROOT/python/devtools"
LIB_SH="$DEVTOOLS_DIR/lib/lib.sh"
DEVSTART="$DEVTOOLS_DIR/bin/devstart"
FIXTURES_DIR="$(dirname "${BASH_SOURCE[0]}")/../fixtures"

setup_mock_home() {
    export MOCK_HOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$MOCK_HOME"
    export PACKAGES_DIRECTORY="$MOCK_HOME/packages"
    printf 'export PACKAGES_DIRECTORY="%s"\n' "$PACKAGES_DIRECTORY" \
        > "$MOCK_HOME/.env-crema-script"
    export HOME="$MOCK_HOME"
}

setup_mock_bin() {
    export TEST_BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$TEST_BIN"
    export PATH="$TEST_BIN:$PATH"
}

add_mock_cmd() {
    local name="$1"
    local exit_code="${2:-0}"
    local output="${3:-}"
    printf '#!/bin/bash\n[ -n "%s" ] && echo "%s"\nexit %s\n' \
        "$output" "$output" "$exit_code" > "$TEST_BIN/$name"
    chmod +x "$TEST_BIN/$name"
}

setup_project_dir() {
    export PROJECT_DIR="$BATS_TEST_TMPDIR/project"
    mkdir -p "$PROJECT_DIR"
    cp "$FIXTURES_DIR/requirements.txt" "$PROJECT_DIR/"
}

source_devstart_functions() {
    BASH_LOAD_FUNCTIONS_ONLY=true source "$DEVSTART"
    unset BASH_LOAD_FUNCTIONS_ONLY
}

create_mock_python3() {
    local version="${1:-3.11}"
    cat > "$TEST_BIN/python3" << MOCKEOF
#!/bin/bash
case "\$1 \$2" in
    "-m venv")
        venv_dir="\${@: -1}"
        mkdir -p "\$venv_dir/bin"
        printf '#!/bin/bash\nif [[ "\$1" == "--version" ]]; then echo "Python ${version}.0"; fi\nexit 0\n' \
            > "\$venv_dir/bin/python"
        chmod +x "\$venv_dir/bin/python"
        printf 'export VIRTUAL_ENV="%s"\ndeactivate() { unset VIRTUAL_ENV; unset -f deactivate; }\n' \
            "\$venv_dir" > "\$venv_dir/bin/activate"
        ;;
    *)
        if [[ "\$1" == "--version" ]] || [[ "\$1" == "-V" ]]; then
            echo "Python ${version}.0"
        fi
        ;;
esac
exit 0
MOCKEOF
    chmod +x "$TEST_BIN/python3"
}

create_mock_pip() {
    cat > "$TEST_BIN/pip" << 'MOCKEOF'
#!/bin/bash
case "$1" in
    show)
        echo "Name: ${2}"
        echo "Version: 1.2.3"
        ;;
    list)
        echo "Package Version Latest Type"
        ;;
    install)
        ;;
esac
exit 0
MOCKEOF
    chmod +x "$TEST_BIN/pip"
}
