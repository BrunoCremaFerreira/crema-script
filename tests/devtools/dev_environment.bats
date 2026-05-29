#!/usr/bin/env bats

load '../bats/bats-support/load'
load '../bats/bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    source_devstart_functions
}

# ── devstop ───────────────────────────────────────────────────────────────────

@test "devstop: unsets DEV_STARTED" {
    export DEV_STARTED="True"
    devstop
    [[ -z "${DEV_STARTED:-}" ]]
}

@test "devstop: restores original PS1" {
    export _OLD_PS1="original$ "
    export PS1="devstart[main]->original$ "
    devstop
    assert_equal "$PS1" "original$ "
}

@test "devstop: calls deactivate when it is defined" {
    export DEACTIVATE_CALLED=false
    deactivate() { DEACTIVATE_CALLED=true; }
    devstop
    [[ "$DEACTIVATE_CALLED" == "true" ]]
}

@test "devstop: does not fail when deactivate is not defined" {
    unset -f deactivate 2>/dev/null || true
    run devstop
    assert_success
}

@test "devstop: undefines devclean after being called" {
    export DEV_STARTED="True"
    devstop
    run declare -f devclean
    assert_failure
}

@test "devstop: undefines devpack after being called" {
    export DEV_STARTED="True"
    devstop
    run declare -f devpack
    assert_failure
}

@test "devstop: does not fail when _OLD_PS1 is unset" {
    unset _OLD_PS1
    run devstop
    assert_success
}

# ── devclean ──────────────────────────────────────────────────────────────────

@test "devclean: removes .pyc files from current directory" {
    setup_project_dir
    cd "$PROJECT_DIR"
    touch "module.pyc"

    devclean

    [[ ! -f "module.pyc" ]]
}

@test "devclean: removes __pycache__ directories" {
    setup_project_dir
    cd "$PROJECT_DIR"
    mkdir -p "subdir/__pycache__"
    touch "subdir/__pycache__/module.cpython-311.pyc"

    devclean

    [[ ! -d "subdir/__pycache__" ]]
}

@test "devclean: does not remove .pyc files inside .venv" {
    setup_project_dir
    cd "$PROJECT_DIR"
    mkdir -p ".venv/lib"
    touch ".venv/lib/module.pyc"

    devclean

    [[ -f ".venv/lib/module.pyc" ]]
}

@test "devclean: succeeds even when there are no .pyc files to remove" {
    setup_project_dir
    cd "$PROJECT_DIR"

    run devclean
    assert_success
}

@test "devclean: prints completion message" {
    setup_project_dir
    cd "$PROJECT_DIR"

    run devclean
    assert_output --partial "removed"
}
