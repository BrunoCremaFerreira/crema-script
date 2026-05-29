#!/usr/bin/env bats
# Integration tests: source devstart and verify the main flow end-to-end.
# Each test uses 'run bash -c' so the sourcing happens in an isolated subshell
# that inherits HOME and PATH from the bats setup (which already has TEST_BIN
# prepended and MOCK_HOME as HOME).

load '../bats/bats-support/load'
load '../bats/bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    create_mock_python3 "3.11"
    create_mock_pip
    setup_project_dir
}

# ── Pre-condition guards ──────────────────────────────────────────────────────

@test "sourcing without requirements.txt prints an error and returns" {
    local empty_dir="$BATS_TEST_TMPDIR/empty"
    mkdir -p "$empty_dir"

    run bash -c "cd '$empty_dir' && source '$DEVSTART' 2>&1"
    assert_output --partial "requirements.txt not found"
}

@test "sourcing when DEV_STARTED=True without -f is a no-op" {
    run bash -c "
        export DEV_STARTED=True
        cd '$PROJECT_DIR'
        source '$DEVSTART' 2>&1
        echo 'AFTER=ok'
    "
    assert_success
    assert_output --partial "AFTER=ok"
    refute_output --partial "Installing requirements"
}

# ── First-run: venv creation ──────────────────────────────────────────────────

@test "sourcing creates a .venv directory on first run" {
    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' 2>&1
        [ -d .venv ] && echo 'VENV_CREATED=true'
    "
    assert_success
    assert_output --partial "VENV_CREATED=true"
}

@test "sourcing sets DEV_STARTED=True" {
    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' 2>&1
        echo \"DEV_STARTED=\$DEV_STARTED\"
    "
    assert_success
    assert_output --partial "DEV_STARTED=True"
}

@test "sourcing modifies PS1 to include devstart prefix" {
    run bash -c "
        export PS1='$ '
        cd '$PROJECT_DIR'
        source '$DEVSTART' 2>&1
        echo \"PS1=\$PS1\"
    "
    assert_success
    assert_output --partial "devstart"
}

@test "sourcing installs requirements via pip" {
    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' 2>&1
    "
    assert_success
    assert_output --partial "Installing requirements"
}

# ── -f flag: force recreate ───────────────────────────────────────────────────

@test "sourcing with -f recreates an existing .venv" {
    mkdir -p "$PROJECT_DIR/.venv/bin"

    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' -f 2>&1
    "
    assert_success
    assert_output --partial "Removing venv"
}

@test "sourcing with -f while DEV_STARTED=True still recreates the venv" {
    mkdir -p "$PROJECT_DIR/.venv/bin"

    run bash -c "
        export DEV_STARTED=True
        cd '$PROJECT_DIR'
        source '$DEVSTART' -f 2>&1
    "
    assert_success
    assert_output --partial "Removing venv"
}

# ── -v flag: Python version selection ────────────────────────────────────────

@test "sourcing with -v uses the specified python version" {
    cat > "$TEST_BIN/python3.11" << 'MOCKEOF'
#!/bin/bash
if [[ "$1 $2" == "-m venv" ]]; then
    venv_dir="${@: -1}"
    mkdir -p "$venv_dir/bin"
    printf '#!/bin/bash\nif [[ "$1" == "--version" ]]; then echo "Python 3.11.0"; fi\nexit 0\n' \
        > "$venv_dir/bin/python"
    chmod +x "$venv_dir/bin/python"
    printf 'export VIRTUAL_ENV="%s"\ndeactivate() { unset VIRTUAL_ENV; }\n' \
        "$venv_dir" > "$venv_dir/bin/activate"
fi
exit 0
MOCKEOF
    chmod +x "$TEST_BIN/python3.11"

    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' -v 3.11 2>&1
    "
    assert_success
    assert_output --partial "Creating new venv"
}

@test "sourcing with -v returns an error when the requested python version is not found" {
    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' -v 3.99 2>&1
    "
    assert_output --partial "not found"
}

# ── Version mismatch: auto-recreate ──────────────────────────────────────────

@test "sourcing with -v recreates venv when existing version differs" {
    mkdir -p "$PROJECT_DIR/.venv/bin"
    cat > "$PROJECT_DIR/.venv/bin/python" << 'EOF'
#!/bin/bash
echo "Python 3.10.0"
EOF
    chmod +x "$PROJECT_DIR/.venv/bin/python"

    cat > "$TEST_BIN/python3.11" << 'MOCKEOF'
#!/bin/bash
if [[ "$1 $2" == "-m venv" ]]; then
    venv_dir="${@: -1}"
    mkdir -p "$venv_dir/bin"
    printf '#!/bin/bash\necho "Python 3.11.0"\n' > "$venv_dir/bin/python"
    chmod +x "$venv_dir/bin/python"
    printf 'export VIRTUAL_ENV="%s"\ndeactivate() { unset VIRTUAL_ENV; }\n' \
        "$venv_dir" > "$venv_dir/bin/activate"
fi
exit 0
MOCKEOF
    chmod +x "$TEST_BIN/python3.11"

    run bash -c "
        cd '$PROJECT_DIR'
        source '$DEVSTART' -v 3.11 2>&1
    "
    assert_success
    assert_output --partial "differs"
}
