#!/bin/bash

# Set directories
FIRMWARE_DIR="/home/erik/a15"
OUTPUT_FILE="/home/erik/crDroid/vendor/sony/sm8650-common/proprietary-files.txt"
TEMP_FILE="/tmp/common_prop_files_tmp.txt"

# Create header
cat > "${OUTPUT_FILE}" << EOL
# Proprietary files for sm8650-common - from XQ-EC72_Customized HK_69.1.A.2.78

EOL

# Function to check if a file is platform-specific (not device-specific)
is_platform_specific() {
    local file="$1"
    if [[ $file =~ pdx245 ]] || \
       [[ $file =~ sony ]] || \
       [[ $file =~ somc ]] || \
       [[ $file =~ semc ]] || \
       [[ $file =~ /acdbdata/ ]]; then
        return 1
    fi
    return 0
}

# Function to convert path to vendor path
convert_to_vendor_path() {
    local file="$1"
    # Remove leading ./ and add vendor prefix
    echo "$file" | sed 's|^\./|vendor/|'
}

# Process all partition directories
process_directory() {
    local partition="$1"
    local dir="${FIRMWARE_DIR}/${partition}"
    
    if [ ! -d "$dir" ]; then
        return
    fi
    
    cd "$dir" || return
    
    echo "Processing ${partition}..."
    
    {
        echo "# ADSP"
        find . -type f -name "adsp*" -o -name "*adsp*" 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# Audio"
        find . -type f -path "*/audio/*" 2>/dev/null | while read -r file; do
            if is_platform_specific "$file"; then
                convert_to_vendor_path "$file"
            fi
        done | sort -u
        
        echo -e "\n# Bluetooth"
        find . -type f \( -path "*/bluetooth/*" -o -name "*bluetooth*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# CNE"
        find . -type f \( -path "*/cne/*" -o -name "*cne*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# DRM"
        find . -type f \( -path "*/drm/*" -o -name "*drm*" -o -name "*widevine*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# Graphics"
        find . -type f \( -path "*/gpu/*" -o -name "*adreno*" \) 2>/dev/null | while read -r file; do
            if is_platform_specific "$file"; then
                convert_to_vendor_path "$file"
            fi
        done | sort -u
        
        echo -e "\n# GPS"
        find . -type f \( -path "*/gps/*" -o -name "*gps*" -o -name "*gnss*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# IMS"
        find . -type f -name "*ims*" 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
        echo -e "\n# Media"
        find . -type f \( -path "*/media/*" -o -name "*media*" \) 2>/dev/null | while read -r file; do
            if is_platform_specific "$file"; then
                convert_to_vendor_path "$file"
            fi
        done | sort -u
        
        echo -e "\n# Qualcomm"
        find . -type f -name "*qc*" -o -name "*qti*" 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u

        echo -e "\n# Radio"
        find . -type f \( -path "*/radio/*" -o -name "*radio*" -o -name "*ril*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u

        echo -e "\n# WiFi"
        find . -type f \( -path "*/wifi/*" -o -name "*wifi*" -o -name "*wlan*" \) 2>/dev/null | while read -r file; do
            convert_to_vendor_path "$file"
        done | sort -u
        
    } >> "${TEMP_FILE}"
}

# Process each partition
for partition in vendor_a vendor_b system_a system_b product_a product_b odm_a odm_b vendor_dlkm_a vendor_dlkm_b system_dlkm_a system_dlkm_b system_ext_a system_ext_b; do
    process_directory "$partition"
done

# Sort and deduplicate while preserving sections
awk '/^#/{if (p){print "\n"};p=1}{print}' "${TEMP_FILE}" | sort -u -s >> "${OUTPUT_FILE}"

# Clean up
rm -f "${TEMP_FILE}"

echo "Generated proprietary-files.txt at ${OUTPUT_FILE}"