#!/usr/bin/env bash

set -e

echo "===================================="
echo "📦 Installing Other Dependencies"
echo "===================================="

# -----------------------------
# UPDATE SYSTEM
# -----------------------------
echo "🔄 Updating system packages..."
sudo apt-get update -y

echo "Installing git"
sudo apt install git

# -----------------------------
# INSTALL CODE-INSIDERS (VS Code Insiders)
# -----------------------------
if command -v code-insiders &>/dev/null; then
    echo "✅ code-insiders is already installed."
else
    echo "⬇️ Installing code-insiders..."
    # Try snap first (most common)
    if command -v snap &>/dev/null; then
        sudo snap install code-insiders --classic
    else
        # Fallback: use Microsoft repository
        echo "   Installing via Microsoft repository..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /usr/share/keyrings/
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
        sudo apt-get update
        sudo apt-get install -y code-insiders
        rm -f /tmp/packages.microsoft.gpg
    fi
    echo "✅ code-insiders installed."
fi

# -----------------------------
# INSTALL CURSOR
# -----------------------------
if command -v cursor &>/dev/null; then
    echo "✅ cursor is already installed."
else
    echo "⬇️ Installing cursor..."
    # Download and install Cursor .deb package from GitHub releases
    curl -L -o /tmp/cursor.deb https://github.com/getcursor/cursor/releases/latest/download/cursor.deb
    sudo dpkg -i /tmp/cursor.deb || true
    sudo apt-get install -f -y  # Fix any dependency issues
    rm -f /tmp/cursor.deb
    echo "✅ cursor installed."
fi

# -----------------------------
# INSTALL NODE.JS
# -----------------------------
if command -v node &>/dev/null; then
    echo "✅ node is already installed ($(node --version))."
else
    echo "⬇️ Installing node..."
    # Install Node.js via NodeSource repository (recommended method)
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✅ node installed ($(node --version))."
fi

# -----------------------------
# INSTALL NPM
# -----------------------------
if command -v npm &>/dev/null; then
    echo "✅ npm is already installed ($(npm --version))."
else
    echo "⬇️ Installing npm..."
    # npm usually comes with node, but install separately if needed
    sudo apt-get install -y npm
    echo "✅ npm installed ($(npm --version))."
fi

# -----------------------------
# INSTALL N (NODE VERSION MANAGER) AND UPDATE TO STABLE
# -----------------------------
if command -v n &>/dev/null; then
    echo "✅ n (node version manager) is already installed."
    echo "🔄 Ensuring stable Node.js version is installed..."
    sudo n stable
    echo "✅ Node.js updated to stable version ($(node --version))."
else
    echo "⬇️ Installing n (node version manager)..."
    sudo npm install -g n
    echo "🔄 Installing stable Node.js version..."
    sudo n stable
    echo "✅ n installed and Node.js updated to stable ($(node --version))."
fi

# -----------------------------
# INSTALL NODEMON (GLOBALLY)
# -----------------------------
if command -v nodemon &>/dev/null; then
    echo "✅ nodemon is already installed ($(nodemon --version 2>/dev/null || echo 'unknown version'))."
else
    echo "⬇️ Installing nodemon globally..."
    sudo npm install -g nodemon
    echo "✅ nodemon installed ($(nodemon --version 2>/dev/null || echo 'unknown version'))."
fi

# -----------------------------
# INSTALL TS-NODE (GLOBALLY)
# -----------------------------
if command -v ts-node &>/dev/null; then
    echo "✅ ts-node is already installed ($(ts-node --version 2>/dev/null || echo 'unknown version'))."
else
    echo "⬇️ Installing ts-node globally..."
    sudo npm install -g ts-node
    echo "✅ ts-node installed ($(ts-node --version 2>/dev/null || echo 'unknown version'))."
fi

# -----------------------------
# INSTALL SCREEN (TERMINAL MULTIPLEXER)
# -----------------------------
if command -v screen &>/dev/null; then
    echo "✅ screen is already installed."
else
    echo "⬇️ Installing screen (terminal session program)..."
    sudo apt-get install -y screen
    echo "✅ screen installed."
fi

# -----------------------------
# INSTALL ENTR (FILE CHANGE MONITOR)
# -----------------------------
if command -v entr &>/dev/null; then
    echo "✅ entr is already installed."
else
    echo "⬇️ Installing entr..."
    sudo apt-get install -y entr
    echo "✅ entr installed."
fi

# -----------------------------
# INSTALL NET-TOOLS (NETWORK UTILITIES)
# -----------------------------
if dpkg -s net-tools &>/dev/null; then
    echo "✅ net-tools is already installed."
else
    echo "⬇️ Installing net-tools..."
    sudo apt-get install -y net-tools
    echo "✅ net-tools installed."
fi

# -----------------------------
# SUMMARY
# -----------------------------
echo "===================================="
echo "✅ Installation complete!"
echo "------------------------------------"
echo "📝 Installed tools:"
echo "   • code-insiders: $(command -v code-insiders 2>/dev/null || echo 'Not found')"
echo "   • cursor: $(command -v cursor 2>/dev/null || echo 'Not found')"
echo "   • node: $(node --version 2>/dev/null || echo 'Not found')"
echo "   • npm: $(npm --version 2>/dev/null || echo 'Not found')"
echo "   • n: $(command -v n 2>/dev/null || echo 'Not found')"
echo "   • nodemon: $(command -v nodemon 2>/dev/null && nodemon --version 2>/dev/null || echo 'Not found')"
echo "   • ts-node: $(command -v ts-node 2>/dev/null && ts-node --version 2>/dev/null || echo 'Not found')"
echo "   • screen: $(command -v screen 2>/dev/null || echo 'Not found')"
echo "   • entr: $(command -v entr 2>/dev/null || echo 'Not found')"
echo "   • net-tools: $(dpkg -s net-tools &>/dev/null && echo 'Installed' || echo 'Not found')"
echo "===================================="
