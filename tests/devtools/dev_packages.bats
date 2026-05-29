#!/usr/bin/env bats

load '../bats/bats-support/load'
load '../bats/bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    source_devstart_functions
    setup_project_dir
    export DEV_STARTED="True"
}

# ── devpack ───────────────────────────────────────────────────────────────────

@test "devpack: creates a zip file in PACKAGES_DIRECTORY" {
    cd "$PROJECT_DIR"

    devpack

    ls "$PACKAGES_DIRECTORY"/*.zip 1>/dev/null 2>&1
}

@test "devpack: zip filename contains the project directory name" {
    cd "$PROJECT_DIR"

    devpack

    local zip_file
    zip_file=$(ls "$PACKAGES_DIRECTORY"/*.zip)
    [[ "$zip_file" == *"project"* ]]
}

@test "devpack: zip filename contains a timestamp" {
    cd "$PROJECT_DIR"

    devpack

    local zip_file
    zip_file=$(ls "$PACKAGES_DIRECTORY"/*.zip | head -1)
    # Timestamp format: YYYYMMDD.HH.MM.SS
    [[ "$zip_file" =~ [0-9]{8}\.[0-9]{2}\.[0-9]{2}\.[0-9]{2} ]]
}

@test "devpack: returns 0 on success" {
    cd "$PROJECT_DIR"

    run devpack
    assert_success
}

# ── devreq ────────────────────────────────────────────────────────────────────

@test "devreq: returns 1 when requirements.txt does not exist" {
    cd "$BATS_TEST_TMPDIR"

    run devreq
    assert_failure
    assert_output --partial "requirements.txt not found"
}

@test "devreq: preserves comment lines in requirements.txt" {
    cd "$PROJECT_DIR"
    create_mock_pip

    devreq

    grep -q "^# Test project dependencies" "$PROJECT_DIR/requirements.txt"
}

@test "devreq: preserves blank lines in requirements.txt" {
    cd "$PROJECT_DIR"
    printf '# comment\n\npackage==1.0\n' > "$PROJECT_DIR/requirements.txt"
    create_mock_pip

    devreq

    grep -q "^$" "$PROJECT_DIR/requirements.txt"
}

@test "devreq: pins packages to their installed version" {
    cd "$PROJECT_DIR"
    printf 'mypackage\n' > "$PROJECT_DIR/requirements.txt"
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1" == "show" ]]; then
    echo "Version: 2.5.0"
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    devreq

    grep -q "mypackage==2.5.0" "$PROJECT_DIR/requirements.txt"
}

@test "devreq: keeps original line when pip show returns no version" {
    cd "$PROJECT_DIR"
    printf 'unknown-package\n' > "$PROJECT_DIR/requirements.txt"
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    devreq

    grep -q "unknown-package" "$PROJECT_DIR/requirements.txt"
}

# ── devdeps ───────────────────────────────────────────────────────────────────

@test "devdeps: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devdeps
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devdeps: runs pip list --outdated when DEV_STARTED is set" {
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1 $2" == "list --outdated" ]]; then
    echo "Package Version Latest"
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    run devdeps
    assert_success
    assert_output --partial "Package"
}

# ── devupgrade ────────────────────────────────────────────────────────────────

@test "devupgrade: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devupgrade
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devupgrade: calls pip install --upgrade for each package" {
    cd "$PROJECT_DIR"
    printf 'requests\n' > "$PROJECT_DIR/requirements.txt"

    local upgrade_called=false
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1 $2" == "install --upgrade" ]]; then
    echo "UPGRADED: $3"
elif [[ "$1" == "show" ]]; then
    echo "Version: 2.9.0"
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"

    run devupgrade
    assert_success
    assert_output --partial "UPGRADED: requests"
}
