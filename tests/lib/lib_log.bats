#!/usr/bin/env bats

load 'bats-support/load'
load 'bats-assert/load'
load '../helpers/common'

setup() {
    setup_mock_home
    setup_mock_bin
    source "$LIB_SH"
}

@test "log: intro mode prints script name and version" {
    run log "My Script" intro "2.0"
    assert_success
    assert_output --partial "My Script"
    assert_output --partial "2.0"
}

@test "log: intro mode prints the logo" {
    run log "Script" intro "1.0"
    assert_success
    assert_output --partial "Crema"
}

@test "log: title mode prints message with border decorations" {
    run log "Section Title" title
    assert_success
    assert_output --partial "Section Title"
    assert_output --partial "+---"
}

@test "log: success mode outputs the message" {
    run log "Operation completed" success
    assert_success
    assert_output --partial "Operation completed"
}

@test "log: information mode outputs the message" {
    run log "Info message" information
    assert_success
    assert_output --partial "Info message"
}

@test "log: warning mode outputs the message" {
    run log "Warning message" warning
    assert_success
    assert_output --partial "Warning message"
}

@test "log: error mode outputs the message" {
    run log "Error occurred" error
    assert_success
    assert_output --partial "Error occurred"
}

@test "log: unknown mode falls back to plain output without decoration" {
    run log "plain text" unknown_mode
    assert_success
    assert_output --partial "plain text"
}
