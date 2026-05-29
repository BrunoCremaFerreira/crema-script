#!/usr/bin/env bats

load '../bats/bats-support/load'
load '../bats/bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    source_devstart_functions
    export DEV_STARTED="True"
}

# ── jup ───────────────────────────────────────────────────────────────────────

@test "jup: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run jup
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "jup: installs jupyter when not present and launches notebook" {
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1" == "show" ]]; then exit 1; fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"
    # python -m pip install prints this, captured by run
    add_mock_cmd "python" 0 "JUPYTER_INSTALLED"
    cat > "$TEST_BIN/jupyter" << 'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$TEST_BIN/jupyter"

    run jup
    assert_success
    assert_output --partial "JUPYTER_INSTALLED"
}

@test "jup: skips install and launches directly when jupyter is present" {
    cat > "$TEST_BIN/pip" << 'EOF'
#!/bin/bash
if [[ "$1" == "show" ]]; then
    echo "Name: jupyter"
    echo "Version: 1.0.0"
fi
exit 0
EOF
    chmod +x "$TEST_BIN/pip"
    cat > "$TEST_BIN/jupyter" << 'EOF'
#!/bin/bash
echo "jupyter:$*"
exit 0
EOF
    chmod +x "$TEST_BIN/jupyter"

    run jup
    # pip show succeeds so no install should happen
    refute_output --partial "pip install"
}

# ── devdoc ────────────────────────────────────────────────────────────────────

@test "devdoc: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devdoc
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devdoc: returns 1 when no doc tool is installed" {
    run devdoc
    assert_failure
    assert_output --partial "No doc tool found"
}

@test "devdoc: uses pdoc when available" {
    cat > "$TEST_BIN/pdoc" << 'EOF'
#!/bin/bash
echo "pdoc:$*"
exit 0
EOF
    chmod +x "$TEST_BIN/pdoc"

    run devdoc
    assert_success
    assert_output --partial "pdoc:"
}

@test "devdoc: falls back to mkdocs when pdoc is absent" {
    cat > "$TEST_BIN/mkdocs" << 'EOF'
#!/bin/bash
echo "mkdocs:$*"
exit 0
EOF
    chmod +x "$TEST_BIN/mkdocs"

    run devdoc
    assert_success
    assert_output --partial "mkdocs:serve"
}

# ── devprofile ────────────────────────────────────────────────────────────────

@test "devprofile: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devprofile
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devprofile: returns 1 when no script argument is provided" {
    run devprofile
    assert_failure
    assert_output --partial "Usage: devprofile"
}

@test "devprofile: runs python cProfile with cumulative sort on the given script" {
    add_mock_cmd "python" 0 "profiling done"

    run devprofile myscript.py
    assert_success
}

# ── devdbuild ─────────────────────────────────────────────────────────────────

@test "devdbuild: returns 1 when DEV_STARTED is not set" {
    unset DEV_STARTED
    run devdbuild
    assert_failure
    assert_output --partial "Run 'source devstart' first"
}

@test "devdbuild: returns 1 when no container runtime is installed" {
    export CONTAINER_CMD=""
    run devdbuild
    assert_failure
    assert_output --partial "Neither Docker nor Podman is installed"
}

@test "devdbuild: returns 1 when Dockerfile is not present" {
    setup_project_dir
    cd "$PROJECT_DIR"
    export CONTAINER_CMD="podman"

    run devdbuild
    assert_failure
    assert_output --partial "Dockerfile not found"
}

@test "devdbuild: builds image using directory name as tag" {
    setup_project_dir
    cd "$PROJECT_DIR"
    touch "$PROJECT_DIR/Dockerfile"
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
echo "podman:$*"
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    export CONTAINER_CMD="podman"

    run devdbuild
    assert_success
    assert_output --partial "podman:build -t project ."
}

@test "devdbuild: uses parent directory name when current dir is named src" {
    local src_dir="$BATS_TEST_TMPDIR/myproject/src"
    mkdir -p "$src_dir"
    touch "$src_dir/Dockerfile"
    cp "$FIXTURES_DIR/requirements.txt" "$src_dir/"
    cd "$src_dir"
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
echo "podman:$*"
exit 0
EOF
    chmod +x "$TEST_BIN/podman"
    export CONTAINER_CMD="podman"

    run devdbuild
    assert_success
    assert_output --partial "podman:build -t myproject ."
}

@test "devdbuild: returns 1 when container build fails" {
    setup_project_dir
    cd "$PROJECT_DIR"
    touch "$PROJECT_DIR/Dockerfile"
    cat > "$TEST_BIN/podman" << 'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$TEST_BIN/podman"
    export CONTAINER_CMD="podman"

    run devdbuild
    assert_failure
    assert_output --partial "Docker build failed"
}

# ── devhelp ───────────────────────────────────────────────────────────────────

@test "devhelp: prints source devstart command" {
    run devhelp
    assert_success
    assert_output --partial "source devstart"
}

@test "devhelp: lists devstop command" {
    run devhelp
    assert_output --partial "devstop"
}

@test "devhelp: lists devclean command" {
    run devhelp
    assert_output --partial "devclean"
}

@test "devhelp: lists devpack command" {
    run devhelp
    assert_output --partial "devpack"
}

@test "devhelp: lists devci command" {
    run devhelp
    assert_output --partial "devci"
}
