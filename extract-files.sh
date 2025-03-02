#!/bin/bash

set -x  # Enable debug mode

DEVICE=sm8650-common
VENDOR=sony

# Get absolute path of script directory
MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: ${MY_DIR}"

# Set up log directory in script directory
LOG_DIR="${MY_DIR}/extraction_logs"
mkdir -p "${LOG_DIR}"

# Set up log files
MAIN_LOG="${LOG_DIR}/extraction_$(date +%Y%m%d_%H%M%S).log"
SUCCESS_LOG="${LOG_DIR}/successful_extractions.txt"
FAILED_LOG="${LOG_DIR}/failed_extractions.txt"

# Initialize logs
echo "Starting extraction at $(date)" > "${MAIN_LOG}"
echo "Successful extractions:" > "${SUCCESS_LOG}"
echo "Failed extractions:" > "${FAILED_LOG}"

# Check source directory
SRC="/home/erik/a15"
if [ ! -d "${SRC}" ]; then
    echo "Error: Source directory ${SRC} not found!"
    exit 1
fi

# Check proprietary-files.txt exists
if [ ! -f "${MY_DIR}/proprietary-files.txt" ]; then
    echo "Error: proprietary-files.txt not found in ${MY_DIR}"
    exit 1
fi

# Create destination directory
DEST_BASE="${MY_DIR}/proprietary"
mkdir -p "${DEST_BASE}"

echo "Starting file extraction..."
echo "Source: ${SRC}"
echo "Destination: ${DEST_BASE}"

# Function to copy directory recursively
copy_directory() {
    local src_dir="$1"
    local dest_dir="$2"
    
    if [ -d "${src_dir}" ]; then
        mkdir -p "${dest_dir}"
        cp -r "${src_dir}"/* "${dest_dir}/" 2>/dev/null || true
        return 0
    fi
    return 1
}

# Process each line in proprietary-files.txt
while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and empty lines
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    
    echo "Processing: ${line}"
    
    # Get the base path without vendor/ prefix
    base_path="${line#vendor/}"
    success=false
    
    # Try each possible source directory
    for dir in vendor_a system_a system_ext_a product_a odm_a vendor_dlkm_a system_dlkm_a; do
        src_path="${SRC}/${dir}/${base_path}"
        dest_path="${DEST_BASE}/vendor/${base_path}"
        
        # Try as file first
        if [ -f "${src_path}" ]; then
            # Create destination directory
            mkdir -p "$(dirname "${dest_path}")"
            cp "${src_path}" "${dest_path}"
            echo "Copied file: ${line} from ${dir}"
            success=true
            break
        # Try as directory
        elif [ -d "${src_path}" ]; then
            mkdir -p "${dest_path}"
            if copy_directory "${src_path}" "${dest_path}"; then
                echo "Copied directory: ${line} from ${dir}"
                success=true
                break
            fi
        fi
    done
    
    if [ "$success" = true ]; then
        echo "${line}" >> "${SUCCESS_LOG}"
    else
        echo "Failed to find: ${line}"
        echo "${line}" >> "${FAILED_LOG}"
    fi
    
done < "${MY_DIR}/proprietary-files.txt"

# Print summary
echo "Extraction complete. Check logs in ${LOG_DIR}"
echo "Successful extractions: $(wc -l < "${SUCCESS_LOG}")"
echo "Failed extractions: $(wc -l < "${FAILED_LOG}")"

if [ -s "${FAILED_LOG}" ]; then
    echo "Failed to extract the following files/directories:"
    cat "${FAILED_LOG}"
fi