#!/usr/bin/env bash

set -e

clear

# -----------------------------
# CONFIGURATION
# -----------------------------
FLUTTER_DIR="/opt/flutter"
ANDROID_SDK_ROOT="$HOME/development/android-sdk"
CMDLINE_TOOLS_DIR="$ANDROID_SDK_ROOT/cmdline-tools/latest"

# -----------------------------
# DEPENDENCY CHECK FUNCTION
# -----------------------------
check_install() {
    local pkg="$1"
    if dpkg -s "$pkg" &> /dev/null; then
        echo "✅ $pkg is already installed."
    else
        echo "⬇️ Installing $pkg..."
        sudo apt-get install -y "$pkg"
    fi
}

# -----------------------------
# UPDATE & INSTALL DEPENDENCIES
# -----------------------------
sudo apt-get update

check_install "xz-utils"
check_install "openjdk-17-jdk"
check_install "libglu1-mesa"
check_install "curl"
check_install "unzip"
check_install "git"
check_install "adb"  # Ensure adb is installed

# -----------------------------
# ADD 32-BIT ARCH FOR EMULATOR
# -----------------------------
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y libc6:i386 libncurses6:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386

# -----------------------------
# INSTALL FLUTTER
# -----------------------------
if [ ! -d "$FLUTTER_DIR" ]; then
    echo "⬇️ Downloading Flutter..."
    sudo git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_DIR"
else
    echo "✅ Flutter already exists at $FLUTTER_DIR"
fi

# -----------------------------
# INSTALL ANDROID CMDLINE TOOLS
# -----------------------------
mkdir -p "$CMDLINE_TOOLS_DIR"

if [ ! -f "$CMDLINE_TOOLS_DIR/bin/sdkmanager" ]; then
    echo "⬇️ Downloading Android command line tools..."
    curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
    unzip -o cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
    mv -f "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$CMDLINE_TOOLS_DIR"
    rm cmdline-tools.zip
else
    echo "✅ Android command line tools already installed."
fi

# -----------------------------
# SET ENVIRONMENT VARIABLES
# -----------------------------
grep -qxF "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" ~/.bashrc || {
    echo '' >> ~/.bashrc
    echo '# Flutter & Android SDK' >> ~/.bashrc
    echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
    echo "export ANDROID_HOME=$ANDROID_SDK_ROOT" >> ~/.bashrc
    echo "export PATH=\$PATH:$CMDLINE_TOOLS_DIR/bin" >> ~/.bashrc
    echo "export PATH=\$PATH:$ANDROID_SDK_ROOT/platform-tools" >> ~/.bashrc
    echo "export PATH=\$PATH:$ANDROID_SDK_ROOT/emulator" >> ~/.bashrc
    echo "export PATH=\$PATH:$FLUTTER_DIR/bin" >> ~/.bashrc
    echo "export PATH=\$PATH:/snap/bin" >> ~/.bashrc
    echo "✅ Environment variables added to ~/.bashrc"
}

# Load env vars immediately
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$PATH:$CMDLINE_TOOLS_DIR/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$FLUTTER_DIR/bin:/snap/bin"

# -----------------------------
# ACCEPT SDK LICENSES
# -----------------------------
echo "📜 Accepting Android SDK licenses..."
yes | "$CMDLINE_TOOLS_DIR/bin/sdkmanager" --licenses

# -----------------------------
# INSTALL ANDROID SDK COMPONENTS
# -----------------------------
echo "📦 Installing Android SDK components..."
"$CMDLINE_TOOLS_DIR/bin/sdkmanager" --install "platform-tools" "platforms;android-35" "build-tools;35.0.0" --sdk_root="$ANDROID_SDK_ROOT" --verbose

# -----------------------------
# CREATE EMULATOR
# -----------------------------
if ! "$CMDLINE_TOOLS_DIR/bin/avdmanager" list avd | grep -q "flutter_emulator"; then
    echo "📱 Creating Android emulator..."
    echo "no" | "$CMDLINE_TOOLS_DIR/bin/avdmanager" create avd -n flutter_emulator -k "system-images;android-35;google_apis;x86_64" --force
else
    echo "✅ Emulator 'flutter_emulator' already exists."
fi

# -----------------------------
# DETECT AND CONFIGURE ANDROID STUDIO
# -----------------------------
ANDROID_STUDIO_BIN=$(command -v android-studio || true)
ANDROID_STUDIO_DIR=""

# Function to verify Android Studio directory
verify_android_studio_dir() {
    local dir="$1"
    if [ -d "$dir" ] && ([ -f "$dir/bin/studio.sh" ] || [ -f "$dir/studio.sh" ] || [ -f "$dir/bin/studio64.vmoptions" ]); then
        return 0
    fi
    return 1
}

# Try to find the actual Android Studio installation directory
if [ -n "$ANDROID_STUDIO_BIN" ]; then
    echo "🔍 Found android-studio command at $ANDROID_STUDIO_BIN"
    
    # Resolve symlinks to find actual location
    REAL_PATH=$(readlink -f "$ANDROID_STUDIO_BIN" 2>/dev/null || echo "$ANDROID_STUDIO_BIN")
    echo "   Resolved to: $REAL_PATH"
    
    # Common Android Studio installation locations (check these first)
    # For snap installations, resolve the symlink to get the actual versioned directory
    SNAP_CURRENT="/snap/android-studio/current"
    if [ -L "$SNAP_CURRENT" ]; then
        SNAP_RESOLVED=$(readlink -f "$SNAP_CURRENT" 2>/dev/null)
        POSSIBLE_DIRS=(
            "$SNAP_RESOLVED"  # Use resolved path first for snap
            "/opt/android-studio"
            "/usr/local/android-studio"
            "$HOME/android-studio"
            "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio/ch-0"
            "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio"
            "/usr/share/android-studio"
        )
    else
        POSSIBLE_DIRS=(
            "/opt/android-studio"
            "/usr/local/android-studio"
            "$HOME/android-studio"
            "/snap/android-studio/current"
            "/snap/android-studio/current/studio"
            "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio/ch-0"
            "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio"
            "/usr/share/android-studio"
        )
    fi
    
    # Check each possible directory
    for dir in "${POSSIBLE_DIRS[@]}"; do
        if verify_android_studio_dir "$dir"; then
            ANDROID_STUDIO_DIR="$dir"
            echo "✅ Found Android Studio installation at $ANDROID_STUDIO_DIR"
            break
        fi
    done
    
    # If not found, try to get parent directory of the binary
    if [ -z "$ANDROID_STUDIO_DIR" ]; then
        # Check if it's a snap installation
        if [[ "$REAL_PATH" == *"/snap/"* ]] || [[ "$ANDROID_STUDIO_BIN" == *"/snap/"* ]]; then
            # For snap, always use the resolved versioned directory (not the symlink)
            # This prevents Flutter from detecting Android Studio twice
            if [ -L "/snap/android-studio/current" ]; then
                # Get the actual versioned directory (not the symlink)
                ACTUAL_SNAP_DIR=$(readlink -f "/snap/android-studio/current" 2>/dev/null)
                if [ -n "$ACTUAL_SNAP_DIR" ] && verify_android_studio_dir "$ACTUAL_SNAP_DIR"; then
                    ANDROID_STUDIO_DIR="$ACTUAL_SNAP_DIR"
                fi
            fi
            
            # Also check for versioned directories directly if symlink resolution didn't work
            if [ -z "$ANDROID_STUDIO_DIR" ] && [ -d "/snap/android-studio" ]; then
                for version_dir in /snap/android-studio/*/; do
                    # Skip the 'current' symlink, only check actual versioned directories
                    if [ ! -L "$version_dir" ] && [ -d "$version_dir" ] && verify_android_studio_dir "$version_dir"; then
                        ANDROID_STUDIO_DIR="$version_dir"
                        break
                    fi
                done
            fi
        fi
        
        # If still not found, try going up directories from the binary
        if [ -z "$ANDROID_STUDIO_DIR" ]; then
            CURRENT_DIR=$(dirname "$REAL_PATH")
            MAX_DEPTH=10
            DEPTH=0
            while [ "$CURRENT_DIR" != "/" ] && [ $DEPTH -lt $MAX_DEPTH ]; do
                if verify_android_studio_dir "$CURRENT_DIR"; then
                    ANDROID_STUDIO_DIR="$CURRENT_DIR"
                    break
                fi
                CURRENT_DIR=$(dirname "$CURRENT_DIR")
                DEPTH=$((DEPTH + 1))
            done
        fi
        
        # Check JetBrains Toolbox locations (may have versioned subdirectories)
        if [ -z "$ANDROID_STUDIO_DIR" ] && [ -d "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio" ]; then
            # Find the latest version
            LATEST_VERSION=$(find "$HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio" -maxdepth 2 -type d -name "ch-*" | sort -V | tail -1)
            if [ -n "$LATEST_VERSION" ] && verify_android_studio_dir "$LATEST_VERSION"; then
                ANDROID_STUDIO_DIR="$LATEST_VERSION"
            fi
        fi
    fi
    
    if [ -n "$ANDROID_STUDIO_DIR" ]; then
        echo "✅ Android Studio directory: $ANDROID_STUDIO_DIR"
        
        # Verify it has the necessary files for Flutter
        if [ -f "$ANDROID_STUDIO_DIR/bin/studio.sh" ] || [ -f "$ANDROID_STUDIO_DIR/studio.sh" ]; then
            echo "   ✓ Found studio.sh"
        fi
        
        # Check for product-info.json (used by Flutter to detect version)
        if [ -f "$ANDROID_STUDIO_DIR/product-info.json" ] || [ -f "$ANDROID_STUDIO_DIR/bin/product-info.json" ]; then
            echo "   ✓ Found product-info.json"
        else
            echo "   ⚠️ product-info.json not found (Flutter may not detect version)"
        fi
        
        # Configure Flutter to use the correct Android Studio directory
        flutter config --android-studio-dir "$ANDROID_STUDIO_DIR"
        echo "   ✓ Configured Flutter with Android Studio directory"
    else
        echo "⚠️ Could not determine Android Studio installation directory"
        echo ""
        echo "   Please find your Android Studio installation and run:"
        echo "   flutter config --android-studio-dir <path-to-android-studio>"
        echo ""
        echo "   Common locations to check:"
        echo "   - /opt/android-studio"
        echo "   - /snap/android-studio/current"
        echo "   - ~/.local/share/JetBrains/Toolbox/apps/AndroidStudio"
        echo ""
        echo "   You can also check where android-studio command points:"
        echo "   readlink -f \$(which android-studio)"
    fi
else
    echo "⚠️ Android Studio not found. Please install it from https://developer.android.com/studio"
fi

# -----------------------------
# CONFIGURE FLUTTER WITH SDK
# -----------------------------
flutter config --android-sdk "$ANDROID_SDK_ROOT"

# -----------------------------
# VERIFY ADB
# -----------------------------
if ! command -v adb &> /dev/null; then
    echo "⚠️ adb not found! Ensure platform-tools installed and PATH includes $ANDROID_SDK_ROOT/platform-tools"
else
    echo "✅ adb is available at $(which adb)"
fi

# -----------------------------
# FLUTTER DOCTOR
# -----------------------------
echo "🧪 Verifying Flutter setup..."
flutter doctor

echo "✅ Installation complete! Run 'flutter devices' to see available devices."
