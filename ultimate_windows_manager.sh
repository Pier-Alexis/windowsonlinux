#!/bin/bash

echo "=== Ultimate Windows On Linux Manager ==="

# Path to store the last opened .exe file
LAST_EXE_FILE="/opt/WindowsOnLinux/last_exe.log"

# Ensure the last .exe file log exists
if [ ! -f "$LAST_EXE_FILE" ]; then
    sudo touch "$LAST_EXE_FILE"
    sudo chmod 666 "$LAST_EXE_FILE"
fi

sudo chmod 666 /opt/WindowsOnLinux/last_exe.log

# Function to open a Windows executable (.exe)
function open_last_exe() {
    local exe_path="$1"

    # If no .exe file is provided, read the last one from the file
    if [ -z "$exe_path" ]; then
        if [ -f "$LAST_EXE_FILE" ] && [ -s "$LAST_EXE_FILE" ]; then
            exe_path=$(cat "$LAST_EXE_FILE")
            echo "No file specified. Using the last opened file: $exe_path"
        else
            echo "Error: No last .exe file found. Please specify a file."
            return 1
        fi
    fi

    # Check if the file exists
    if [ ! -f "$exe_path" ]; then
        echo "Error: File '$exe_path' does not exist."
        return 1
    fi

    # Run the .exe file with Wine
    echo "Running '$exe_path' with Wine..."
    wine "$exe_path"

    # Save the path of the last opened .exe file
    echo "$exe_path" | sudo tee "$LAST_EXE_FILE" > /dev/null
    echo "File '$exe_path' has been saved as the last opened file."
}

# Automatically open the last file if no arguments are provided
if [ "$#" -eq 0 ]; then
    open_last_exe
else
    open_last_exe "$1"
fi

# Same logic of the .exe, adapted to .msi using msiexec
# Path to store the last opened .msi file
LAST_MSI_FILE="/opt/WindowsOnLinux/last_msi.log"

# Ensure the last .msi file log exists
if [ ! -f "$LAST_MSI_FILE" ]; then
    sudo touch "$LAST_MSI_FILE"
    sudo chmod 666 "$LAST_MSI_FILE"
fi

# Function to open a Windows installer (.msi)
function open_last_msi() {
    local msi_path="$1"

    # If no .msi file is provided, read the last one from the file
    if [ -z "$msi_path" ]; then
        if [ -f "$LAST_MSI_FILE" ] && [ -s "$LAST_MSI_FILE" ]; then
            msi_path=$(cat "$LAST_MSI_FILE")
            echo "No file specified. Using the last opened file: $msi_path"
        else
            echo "Error: No last .msi file found. Please specify a file."
            return 1
        fi
    fi

    # Check if the file exists
    if [ ! -f "$msi_path" ]; then
        echo "Error: File '$msi_path' does not exist."
        return 1
    fi

    # Run the .msi file with Wine's msiexec
    echo "Running '$msi_path' with msiexec..."
    wine msiexec /i "$msi_path"

    # Save the path of the last opened .msi file
    echo "$msi_path" | sudo tee "$LAST_MSI_FILE" > /dev/null
    echo "File '$msi_path' has been saved as the last opened file."
}


function setup_steam_with_proton() {
    echo "=== Installation and configuration of Steam with Proton ==="

    echo "[1/3] Installation of Steam..."
    if ! command -v steam &> /dev/null; then
        sudo apt update
        sudo apt install -y steam
        sudo apt install gamemode
        sudo apt update
        sudo apt upgrade
    else
        echo "Steam is already installed."
        sudo apt update
        sudo apt upgrade
    fi
    
    echo "[2/3] Installation of Proton-GE..."
    mkdir -p /opt/WindowsOnLinux/compatibilitytools.d
    proton_ge_url="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton7-42/GE-Proton7-42.tar.gz"
    wget "$proton_ge_url" -O ~/proton-ge.tar.gz
    tar -xzf ~/proton-ge.tar.gz -C /opt/WindowsOnLinux/compatibilitytools.d
    
    echo "[3/3] Configuration of Steam to use Proton-GE..."
    mkdir -p /opt/WindowsOnLinux/steam/steam/steamapps/compatdata
    echo "Proton-GE installed /opt/WindowsOnLinux/compatibilitytools.d"

    echo "=== Installation et configuration de Steam avec Proton terminées ! ==="
    echo "Redémarrez Steam et configurez les jeux pour utiliser Proton-GE dans les propriétés."
}

# Fonction to configure Fortnite
function setup_fortnite_proton() {
    echo "=== Configuration of an minimal Proton environment for Fortnite ==="

    # Creating needed repository
    echo "[1/4] Creation of repository..."
    mkdir -p ~/proton_fortnite/prefix
    export WINEPREFIX=~/proton_fortnite/prefix
    sudo apt install gamemode

    # Installation of DXVK
    echo "[2/4] Downloading and installating DXVK for Fortnite..."
    mkdir -p ~/proton_fortnite/dxvk
    wget https://github.com/doitsujin/dxvk/releases/download/v2.0/dxvk-2.0.tar.gz -O ~/proton_fortnite/dxvk/dxvk.tar.gz
    tar -xvf ~/proton_fortnite/dxvk/dxvk.tar.gz -C ~/proton_fortnite/dxvk

    # Installation of dependencies via winetricks
    echo "[3/4] Installation of dependencies via winetricks"
    winetricks -q vcrun2019 dxvk

    # Creating of a launch script for Fortnite
    echo "[4/4] Creating of a launch script for Fortnite"
    cat <<EOF > ~/proton_fortnite/launch_fortnite.sh
#!/bin/bash
export WINEPREFIX=~/proton_fortnite/prefix
export WINEDEBUG=-all
export DXVK_HUD=1

# Launch Fortnite via Epic Games Launcher
wine ~/.wine/drive_c/Program\\ Files/Epic\\ Games/Launcher/Portal/Binaries/Win64/EpicGamesLauncher.exe

EOF

    chmod +x ~/proton_fortnite/launch_fortnite.sh
    echo "=== Configuration finished ! Utilisez ~/proton_fortnite/launch_fortnite.sh pour lancer Fortnite ==="
}

function show_menu() {
    echo "Choose an option :"
    echo "1. Setup Fortnite"
    echo "2. Launch a game or a Windows Application"
    echo "3. Diagnostic an application or a game (exe only)"
    echo "4. Setup Steam with Proton"
    echo "5. Exit"
}

function launch_application() {
    read -p "Type the full path of the file starting at / : " file_path
    if [[ "home/$file_path" == *.msi ]]; then
        ./install_msi.sh "$file_path" /i
    elif [[ "$file_path" == *.exe ]]; then
        wine "$file_path"
    else
        echo "Invalid .exe or .msi file : $file_path"
    fi
}

function diagnose_application() {
    read -p "Type the full path of the .msi or .exe file : " file_path
    echo "Starting the diagnostic for $file_path ..."
    WINEDEBUG=+all wine "$file_path" &> wine_diagnostic.log
    echo "Diagnostic finished. For further details go check the wine_diagnostic.log file created."
}

while true; do
    show_menu
    read -p "Your choice : " main_choice
    case $main_choice in
        1) setup_fortnite_proton ;;
        2) launch_application ;;
        3) diagnose_application ;;
        4) steam_setup_with_proton ;;
        5) echo "Closing Manager." ; exit 0 ;;
        *) echo "Invalid Choice. Put a valid number" ;;
    esac
done
