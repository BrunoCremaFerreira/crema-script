#!/usr/bin/env bats

load 'bats-support/load'
load 'bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    source_devstart_functions
    export DEV_STARTED="True"
}

# ── devtest ───────────────────────────────────────────────────────────────────

@test "devtest: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devtest
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devtest: returns 1 when pytest is not installed" {
    run devtest
    assert_failure
    assert_output --partial "pytest not found"
}

@test "devtest: runs pytest --tb=short without coverage when pytest-cov is absent" {
    cat > "$TEST_BIN/pytest" << 'EOF'
#!/bin/bash
echo "PYTEST_ARGS: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/pytest"
    # pip show pytest-cov returns nothing (exit 1)
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1" == "show" ]] && [[ "$2" == "pytest-cov" ]]; then
    exit 1
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    run devtest
    assert_success
    assert_output --partial "--tb=short"
    refute_output --partial "--cov"
}

@test "devtest: runs pytest with --cov when pytest-cov is installed" {
    cat > "$TEST_BIN/pytest" << 'EOF'
#!/bin/bash
echo "PYTEST_ARGS: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/pytest"
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1" == "show" ]] && [[ "$2" == "pytest-cov" ]]; then
    echo "Name: pytest-cov"
    echo "Version: 4.0.0"
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    run devtest
    assert_success
    assert_output --partial "--cov"
}

# ── devlint ───────────────────────────────────────────────────────────────────

@test "devlint: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devlint
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devlint: returns 1 when no linter is installed" {
    run devlint
    assert_failure
    assert_output --partial "No linter found"
}

@test "devlint: uses ruff when available" {
    cat > "$TEST_BIN/ruff" << 'EOF'
#!/bin/bash
echo "RUFF: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/ruff"

    run devlint
    assert_success
    assert_output --partial "RUFF: check ."
}

@test "devlint: falls back to flake8 when ruff is absent" {
    cat > "$TEST_BIN/flake8" << 'EOF'
#!/bin/bash
echo "FLAKE8: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/flake8"

    run devlint
    assert_success
    assert_output --partial "FLAKE8: ."
}

# ── devformat ─────────────────────────────────────────────────────────────────

@test "devformat: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devformat
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devformat: returns 1 when no formatter is installed" {
    run devformat
    assert_failure
    assert_output --partial "No formatter found"
}

@test "devformat: uses ruff when available" {
    cat > "$TEST_BIN/ruff" << 'EOF'
#!/bin/bash
echo "RUFF: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/ruff"

    run devformat
    assert_success
    assert_output --partial "RUFF: format ."
}

@test "devformat: falls back to black when ruff is absent" {
    cat > "$TEST_BIN/black" << 'EOF'
#!/bin/bash
echo "BLACK: $*"
exit 0
EOF
    chmod +x "$TEST_BIN/black"

    run devformat
    assert_success
    assert_output --partial "BLACK: ."
}

# ── devci ─────────────────────────────────────────────────────────────────────

@test "devci: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devci
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devci: runs format, lint, and test in sequence" {
    local calls=""
    cat > "$TEST_BIN/ruff" << 'EOF'
#!/bin/bash
echo "ruff:$1"
exit 0
EOF
    chmod +x "$TEST_BIN/ruff"
    cat > "$TEST_BIN/pytest" << 'EOF'
#!/bin/bash
echo "pytest"
exit 0
EOF
    chmod +x "$TEST_BIN/pytest"
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$TEST_BIN/pip"

    run devci
    assert_success
    assert_output --partial "ruff:format"
    assert_output --partial "ruff:check"
    assert_output --partial "pytest"
}

@test "devci: stops pipeline when devformat fails" {
    cat > "$TEST_BIN/ruff" << 'EOF'
#!/bin/bash
if [[ "$1" == "format" ]]; then exit 1; fi
echo "ruff:$1"
exit 0
EOF
    chmod +x "$TEST_BIN/ruff"

    run devci
    assert_failure
    refute_output --partial "ruff:check"
}
