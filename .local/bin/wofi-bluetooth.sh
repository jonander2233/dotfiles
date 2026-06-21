#!/usr/bin/env bash
#
# Forked from the excellent rofi-bluetooth script by Nick Clyde
# (https://github.com/nickclyde/rofi-bluetooth). Simply calls wofi instead of rofi.
#
# Depends on: wofi, bluez-utils (contains bluetoothctl)

# Constants
divider="---------"
goback="Back"
wofi_command="wofi -d -i -p"

# Helper function to clear control characters from bluetoothctl (used only for info/status)
_bluetoothctl() {
    echo "$*" | bluetoothctl 2>/dev/null \
        | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//g' \
        | grep -v -E '^\[.*\]>|^Waiting to connect|^Agent registered|^\[NEW\]|^\[DEL\]|^\[CHG\]|^$'
}

# Wait for status change helper
wait_for_state() {
    local mac="$1"
    local state="$2"
    local expected="$3"

    for i in {1..15}; do
        if _bluetoothctl info "$mac" | grep -q "^$state: $expected"; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

# Checks if bluetooth controller is powered on
power_on() {
    if _bluetoothctl show | grep -q "Powered: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles power state
toggle_power() {
    if power_on; then
        bluetoothctl power off > /dev/null 2>&1
        sleep 0.5
        show_menu
    else
        if rfkill list bluetooth | grep -q 'blocked: yes'; then
            rfkill unblock bluetooth && sleep 1
        fi
        bluetoothctl power on > /dev/null 2>&1
        sleep 0.5
        show_menu
    fi
}

# Checks if controller is scanning for new devices
scan_on() {
    if _bluetoothctl show | grep -q "Discovering: yes"; then
        echo "Scan: on"
        return 0
    else
        echo "Scan: off"
        return 1
    fi
}

# Toggles scanning state
toggle_scan() {
    if scan_on; then
        local pid
        pid=$(pgrep -f "bluetoothctl.*scan on")
        [ -n "$pid" ] && kill "$pid"
        bluetoothctl scan off > /dev/null 2>&1
        show_menu
    else
        # Background scan for 20 seconds to give the user time to see devices
        bluetoothctl --timeout 20 scan on > /dev/null 2>&1 &
        echo "Scanning..."
        sleep 1.5
        show_menu
    fi
}

# Checks if controller is able to pair to devices
pairable_on() {
    if _bluetoothctl show | grep -q "Pairable: yes"; then
        echo "Pairable: on"
        return 0
    else
        echo "Pairable: off"
        return 1
    fi
}

# Toggles pairable state
toggle_pairable() {
    if pairable_on; then
        bluetoothctl pairable off > /dev/null 2>&1
        show_menu
    else
        bluetoothctl pairable on > /dev/null 2>&1
        show_menu
    fi
}

# Checks if controller is discoverable by other devices
discoverable_on() {
    if _bluetoothctl show | grep -q "Discoverable: yes"; then
        echo "Discoverable: on"
        return 0
    else
        echo "Discoverable: off"
        return 1
    fi
}

# Toggles discoverable state
toggle_discoverable() {
    if discoverable_on; then
        bluetoothctl discoverable off > /dev/null 2>&1
        show_menu
    else
        bluetoothctl discoverable on > /dev/null 2>&1
        show_menu
    fi
}

# Checks if a device is connected
device_connected() {
    if _bluetoothctl info "$1" | grep -q "Connected: yes"; then
        return 0
    else
        return 1
    fi
}

# Toggles device connection
toggle_connection() {
    local mac="$1"
    local device_str="$2"
    if device_connected "$mac"; then
        bluetoothctl disconnect "$mac" > /dev/null 2>&1
        wait_for_state "$mac" "Connected" "no"
        device_menu "$device_str"
    else
        # Se lanza de forma nativa e interactiva en segundo plano para que no bloquee el script
        bluetoothctl connect "$mac" > /dev/null 2>&1 &
        wait_for_state "$mac" "Connected" "yes"
        device_menu "$device_str"
    fi
}

# Checks if a device is paired
device_paired() {
    if _bluetoothctl info "$1" | grep -q "Paired: yes"; then
        echo "Paired: yes"
        return 0
    else
        echo "Paired: no"
        return 1
    fi
}

# Toggles device paired state
toggle_paired() {
    local mac="$1"
    local device_str="$2"
    if device_paired "$mac" | grep -q "yes"; then
        bluetoothctl remove "$mac" > /dev/null 2>&1
        wait_for_state "$mac" "Paired" "no"
        device_menu "$device_str"
    else
        bluetoothctl pair "$mac" > /dev/null 2>&1 &
        wait_for_state "$mac" "Paired" "yes"
        device_menu "$device_str"
    fi
}

# Checks if a device is trusted
device_trusted() {
    if _bluetoothctl info "$1" | grep -q "Trusted: yes"; then
        echo "Trusted: yes"
        return 0
    else
        echo "Trusted: no"
        return 1
    fi
}

# Toggles device trust state
toggle_trust() {
    local mac="$1"
    local device_str="$2"
    if device_trusted "$mac" | grep -q "yes"; then
        bluetoothctl untrust "$mac" > /dev/null 2>&1
        wait_for_state "$mac" "Trusted" "no"
        device_menu "$device_str"
    else
        bluetoothctl trust "$mac" > /dev/null 2>&1
        wait_for_state "$mac" "Trusted" "yes"
        device_menu "$device_str"
    fi
}

# Prints a short string with the current bluetooth status
print_status() {
    if power_on; then
        printf ''
        local paired_devices_cmd="devices Paired"
        if (( $(echo "$(_bluetoothctl version | cut -d ' ' -f 2) < 5.65" | bc -l) )); then
            paired_devices_cmd="paired-devices"
        fi

        mapfile -t paired_devices < <(_bluetoothctl $paired_devices_cmd | grep Device | cut -d ' ' -f 2)
        local counter=0

        for device in "${paired_devices[@]}"; do
            if device_connected "$device"; then
                local device_alias
                device_alias=$(_bluetoothctl info "$device" | grep "Alias" | cut -d ' ' -f 2-)
                if [ $counter -gt 0 ]; then
                    printf ", %s" "$device_alias"
                else
                    printf " %s" "$device_alias"
                fi
                ((counter++))
            fi
        done
        printf "\n"
    else
        echo ""
    fi
}

# Submenu for a specific device
device_menu() {
    local device="$1"

    # Get device name and mac address safely
    local device_name
    device_name=$(echo "$device" | cut -d ' ' -f 3-)
    local mac
    mac=$(echo "$device" | cut -d ' ' -f 2)

    # Build options
    local connected paired trusted options chosen
    if device_connected "$mac"; then
        connected="Connected: yes"
    else
        connected="Connected: no"
    fi
    paired=$(device_paired "$mac")
    trusted=$(device_trusted "$mac")
    options="$connected\n$paired\n$trusted\n$divider\n$goback\nExit"

    # Open wofi menu
    chosen=$(echo -e "$options" | $wofi_command "$device_name")

    case "$chosen" in
        "" | "$divider" | "Exit")
            echo "Exit Menu."
            ;;
        "$connected")
            toggle_connection "$mac" "$device"
            ;;
        "$paired")
            toggle_paired "$mac" "$device"
            ;;
        "$trusted")
            toggle_trust "$mac" "$device"
            ;;
        "$goback")
            show_menu
            ;;
    esac
}

# Opens the primary menu
show_menu() {
    local power devices scan pairable discoverable options lines chosen target_device

    if power_on; then
        power="Power: on"

        # Display "MAC Name" so that parsing the choice is 100% accurate
        devices=$(bluetoothctl devices | grep Device | sed 's/^Device //')

        scan=$(scan_on)
        pairable=$(pairable_on)
        discoverable=$(discoverable_on)

        options="$devices\n$divider\n$power\n$scan\n$pairable\n$discoverable\nExit"
    else
        power="Power: off"
        options="$power\nExit"
    fi

    lines=$(echo -e "$options" | wc -l)
    chosen=$(echo -e "$options" | $wofi_command "Bluetooth" -L "$lines")

    case "$chosen" in
        "" | "$divider" | "Exit")
            echo "Exit Menu."
            ;;
        "$power")
            toggle_power
            ;;
        "$scan")
            toggle_scan
            ;;
        "$discoverable")
            toggle_discoverable
            ;;
        "$pairable")
            toggle_pairable
            ;;
        *)
            # Extract the mac address from the selection (first word of the chosen line)
            local chosen_mac
            chosen_mac=$(echo "$chosen" | cut -d ' ' -f 1)
            
            # Reconstruct the line format to match standard device_menu inputs
            target_device=$(bluetoothctl devices | grep "$chosen_mac")
            
            if [[ -n "$target_device" ]]; then 
                device_menu "$target_device"
            fi
            ;;
    esac
}

case "$1" in
    --status)
        print_status
        ;;
    *)
        show_menu
        ;;
esac
