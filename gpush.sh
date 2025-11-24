#!/usr/bin/env bash
# gpush.sh — quick add/commit/push with optional exit

set -Eeuo pipefail

MESSAGE="${1:-}"
KILL_SESSION="${2:-true}"   # default true

# --- verify git repo ---
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "❌ Not inside a Git repository."
    exit 1
fi

# --- increment package.json version if it exists ---
increment_package_version() {
    local pkg_file="package.json"
    
    if [[ ! -f "$pkg_file" ]]; then
        return 0  # No package.json, skip version increment
    fi
    
    if command -v jq >/dev/null 2>&1; then
        # Use jq to parse and increment version
        local current_version=$(jq -r '.version' "$pkg_file" 2>/dev/null || echo "")
        
        if [[ -z "$current_version" || "$current_version" == "null" ]]; then
            echo "ℹ️ No version field found in package.json, skipping version increment."
            return 0
        fi
        
        # Increment patch version (e.g., 1.2.3 -> 1.2.4)
        IFS='.' read -ra VERSION_PARTS <<< "$current_version"
        local major="${VERSION_PARTS[0]:-0}"
        local minor="${VERSION_PARTS[1]:-0}"
        local patch="${VERSION_PARTS[2]:-0}"
        
        patch=$((patch + 1))
        local new_version="${major}.${minor}.${patch}"
        
        # Update package.json with new version
        jq --arg version "$new_version" '.version = $version' "$pkg_file" > "${pkg_file}.tmp" && \
        mv "${pkg_file}.tmp" "$pkg_file"
        
        echo "📦 Incremented version: $current_version -> $new_version"
    else
        # Fallback: use sed/awk if jq is not available
        echo "⚠️ jq not found, attempting version increment with sed..."
        local current_version=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$pkg_file" 2>/dev/null || echo "")
        
        if [[ -z "$current_version" ]]; then
            echo "ℹ️ Could not parse version from package.json, skipping version increment."
            return 0
        fi
        
        # Increment patch version
        IFS='.' read -ra VERSION_PARTS <<< "$current_version"
        local major="${VERSION_PARTS[0]:-0}"
        local minor="${VERSION_PARTS[1]:-0}"
        local patch="${VERSION_PARTS[2]:-0}"
        
        patch=$((patch + 1))
        local new_version="${major}.${minor}.${patch}"
        
        # Update using sed (works on most systems)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS sed requires -i '' for in-place editing
            sed -i '' "s/\"version\": \"${current_version}\"/\"version\": \"${new_version}\"/" "$pkg_file"
        else
            # Linux sed
            sed -i "s/\"version\": \"${current_version}\"/\"version\": \"${new_version}\"/" "$pkg_file"
        fi
        
        echo "📦 Incremented version: $current_version -> $new_version"
    fi
}

# Increment version before committing
increment_package_version

if [[ -z "$MESSAGE" ]]; then
    echo "❌ No commit message provided."
else
    git add . && git commit -am "$MESSAGE" || {
        echo "ℹ️ Nothing to commit (working tree clean)."
    }
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    git push origin "$CURRENT_BRANCH"
fi

# --- optional exit ---
shopt -s nocasematch
if [[ "$KILL_SESSION" == "true" || "$KILL_SESSION" == "1" || "$KILL_SESSION" == "yes" ]]; then
    echo "killSession=true: exiting…"
    exit
fi

exit