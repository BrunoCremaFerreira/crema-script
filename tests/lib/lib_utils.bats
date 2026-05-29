#!/usr/bin/env bats

load '../bats/bats-support/load'
load '../bats/bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
}

# ── die ──────────────────────────────────────────────────────────────────────

@test "die: exits with the given exit code" {
    run bash -c "source '$LIB_SH'; die 'fatal error' 42"
    assert_equal "$status" 42
}

@test "die: exits with exit code 1 when passed 1" {
    run bash -c "source '$LIB_SH'; die 'error' 1"
    assert_failure
}

@test "die: prints the error message to output" {
    run bash -c "source '$LIB_SH'; die 'something broke' 1"
    assert_output --partial "something broke"
}

@test "die: prints abort notice alongside the message" {
    run bash -c "source '$LIB_SH'; die 'abort me' 1"
    assert_output --partial "Script aborted"
}

# ── checkDependency ───────────────────────────────────────────────────────────

@test "checkDependency: returns 0 when command exists" {
    add_mock_cmd "mycmd" 0
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkDependency mycmd MyCmd"
    assert_success
}

@test "checkDependency: returns 1 when command does not exist" {
    run bash -c "export PATH='$TEST_BIN'; source '$LIB_SH'; checkDependency nonexistentcmd NonExistent"
    assert_failure
}

@test "checkDependency: prints success marker when command is found" {
    add_mock_cmd "mycmd" 0
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkDependency mycmd MyCmd"
    assert_output --partial "[X] MyCmd is installed"
}

@test "checkDependency: prints error marker when command is not found" {
    run bash -c "export PATH='$TEST_BIN'; source '$LIB_SH'; checkDependency nonexistentcmd NonExistent"
    assert_output --partial "[ ] NonExistent is not installed"
}

# ── checkIfIsRoot ─────────────────────────────────────────────────────────────

@test "checkIfIsRoot: returns 0 when running as root (uid 0)" {
    cat > "$TEST_BIN/id" << 'EOF'
#!/bin/bash
echo "0"
EOF
    chmod +x "$TEST_BIN/id"
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkIfIsRoot"
    assert_success
}

@test "checkIfIsRoot: returns 1 when not running as root (uid > 0)" {
    cat > "$TEST_BIN/id" << 'EOF'
#!/bin/bash
echo "1000"
EOF
    chmod +x "$TEST_BIN/id"
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkIfIsRoot"
    assert_failure
}

@test "checkIfIsRoot: prints root confirmation when uid is 0" {
    cat > "$TEST_BIN/id" << 'EOF'
#!/bin/bash
echo "0"
EOF
    chmod +x "$TEST_BIN/id"
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkIfIsRoot"
    assert_output --partial "Running as Root"
}

@test "checkIfIsRoot: prints error when not root" {
    cat > "$TEST_BIN/id" << 'EOF'
#!/bin/bash
echo "1000"
EOF
    chmod +x "$TEST_BIN/id"
    run bash -c "export PATH='$TEST_BIN:\$PATH'; source '$LIB_SH'; checkIfIsRoot"
    assert_output --partial "Not running as Root"
}
