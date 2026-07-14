#!/usr/bin/env bash

install_android() {
    begin_category android || return 0
    section "🤖 Android Development"
    install_core
    apt_install openjdk-17-jdk

    local android_home="$HOME/Android/Sdk"
    local cmdline_dir="$android_home/cmdline-tools/latest"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$android_home/cmdline-tools"
    fi

    if [ ! -x "$cmdline_dir/bin/sdkmanager" ]; then
        info "Installing Android command-line tools"
        if [ "$DRY_RUN" = true ]; then
            color "$PURPLE" "🧪 DRY RUN: would download Android command-line tools"
        else
            local tmp_zip="/tmp/android-commandlinetools.zip"
            curl -L -o "$tmp_zip" "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
            rm -rf "$android_home/cmdline-tools/latest" "$android_home/cmdline-tools/cmdline-tools"
            unzip -q "$tmp_zip" -d "$android_home/cmdline-tools"
            mv "$android_home/cmdline-tools/cmdline-tools" "$cmdline_dir"
        fi
    else
        success "Android command-line tools already installed"
    fi

    append_once "$HOME/.zshrc" 'export ANDROID_HOME="$HOME/Android/Sdk"'
    append_once "$HOME/.zshrc" 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"'
    append_once "$HOME/.bashrc" 'export ANDROID_HOME="$HOME/Android/Sdk"'
    append_once "$HOME/.bashrc" 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"'

    if [ "$DRY_RUN" = true ]; then
        color "$PURPLE" "🧪 DRY RUN: would install Android SDK packages and Pixel 9 AVD"
        return 0
    fi

    yes | "$cmdline_dir/bin/sdkmanager" --licenses >/dev/null || true
    "$cmdline_dir/bin/sdkmanager" "platform-tools" "emulator" "platforms;android-35" "build-tools;35.0.0" "system-images;android-35;google_apis;x86_64"
    if "$cmdline_dir/bin/avdmanager" list avd | grep -q "Pixel_9"; then
        success "Pixel_9 AVD already exists"
    else
        echo "no" | "$cmdline_dir/bin/avdmanager" create avd -n Pixel_9 -k "system-images;android-35;google_apis;x86_64" -d "pixel_9" ||
            warn "Pixel 9 device profile unavailable; create the AVD manually in Android Studio."
    fi
}
