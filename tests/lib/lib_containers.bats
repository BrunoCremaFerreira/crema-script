#!/usr/bin/env bats

load 'bats-support/load'
load 'bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
}

# ── CONTAINER_CMD Detection ───────────────────────────────────────────────────

@test "CONTAINER_CMD is docker when only docker is available" {
    add_mock_cmd "docker" 0
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        echo \"CMD=\$CONTAINER_CMD\"
    "
    assert_output --partial "CMD=docker"
}

@test "CONTAINER_CMD is podman when only podman is available" {
    add_mock_cmd "podman" 0
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        echo \"CMD=\$CONTAINER_CMD\"
    "
    assert_output --partial "CMD=podman"
}

@test "CONTAINER_CMD is empty when neither docker nor podman is available" {
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        echo \"CMD=\$CONTAINER_CMD\"
    "
    assert_output "CMD="
}

@test "CONTAINER_CMD prefers docker over podman when both are available" {
    add_mock_cmd "docker" 0
    add_mock_cmd "podman" 0
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        echo \"CMD=\$CONTAINER_CMD\"
    "
    assert_output --partial "CMD=docker"
}

# ── startContainer ────────────────────────────────────────────────────────────

@test "startContainer: returns error when no container runtime is installed" {
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        CONTAINER_CMD=''
        startContainer myapp
    "
    assert_failure
    assert_output --partial "Neither Docker nor Podman is installed"
}

@test "startContainer: reports container already running and skips start" {
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
if [[ "$1" == "ps" ]]; then echo "abc123def456"; fi
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    run bash -c "
        export PATH='$TEST_BIN:\$PATH'
        source '$LIB_SH'
        startContainer myapp
    "
    assert_success
    assert_output --partial "already started"
}

@test "startContainer: starts a stopped container" {
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
if [[ "$1" == "ps" ]]; then echo ""; fi
if [[ "$1 $2" == "container start" ]]; then echo "myapp"; fi
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    run bash -c "
        export PATH='$TEST_BIN:\$PATH'
        source '$LIB_SH'
        startContainer myapp
    "
    assert_success
}

@test "startContainer: uses sudo with docker" {
    add_mock_cmd "docker" 0
    cat > "$TEST_BIN/sudo" << 'EOF'
#!/bin/bash
exec "$@"
EOF
    chmod +x "$TEST_BIN/sudo"
    cat > "$TEST_BIN/docker" << 'EOF'
#!/bin/bash
if [[ "$1" == "ps" ]]; then echo "abc123"; fi
exit 0
EOF
    chmod +x "$TEST_BIN/docker"
    run bash -c "
        export PATH='$TEST_BIN:\$PATH'
        source '$LIB_SH'
        startContainer myapp
    "
    assert_success
    assert_output --partial "already started"
}

# ── stopContainer ─────────────────────────────────────────────────────────────

@test "stopContainer: returns error when no container runtime is installed" {
    run bash -c "
        export PATH='$TEST_BIN'
        source '$LIB_SH'
        CONTAINER_CMD=''
        stopContainer myapp
    "
    assert_failure
    assert_output --partial "Neither Docker nor Podman is installed"
}

@test "stopContainer: reports container already stopped and skips stop" {
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
if [[ "$1" == "ps" ]]; then echo ""; fi
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    run bash -c "
        export PATH='$TEST_BIN:\$PATH'
        source '$LIB_SH'
        stopContainer myapp
    "
    assert_success
    assert_output --partial "already stopped"
}

@test "stopContainer: stops a running container" {
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
if [[ "$1" == "ps" ]]; then echo "abc123def456"; fi
if [[ "$1 $2" == "container stop" ]]; then echo "myapp"; fi
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    run bash -c "
        export PATH='$TEST_BIN:\$PATH'
        source '$LIB_SH'
        stopContainer myapp
    "
    assert_success
}
