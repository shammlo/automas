#!/usr/bin/env bash

install_core() {
    begin_category core || return 0
    section "🧱 Core Development Tools"
    apt_install git curl wget unzip zip build-essential ca-certificates gnupg software-properties-common
}
