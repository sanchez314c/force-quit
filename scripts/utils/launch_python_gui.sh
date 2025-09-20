#!/bin/bash
# Claude ForceQUIT - Python GUI Launcher
# Launches the Python version of ForceQUIT with GUI and system tray

cd "$(dirname "$0")"

echo "🚀 Launching Claude ForceQUIT (Python GUI)..."

# Check if conda is available and activate base environment
if command -v conda &> /dev/null; then
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda activate base
fi

# Install dependencies if needed
python3 -c "import pystray, PIL" 2>/dev/null || {
    echo "📦 Installing Python dependencies..."
    pip install pystray pillow
}

# Launch the Python GUI
python3 src/claude_forcequit.py