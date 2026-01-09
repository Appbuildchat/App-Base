#!/bin/bash

# =============================================================================
# PERMISSIONS SETUP SCRIPT
# =============================================================================
# This script adds platform permissions based on selected features/addons.
# Run this after start.sh to configure permissions for your app.
#
# Usage: ./scripts/permissions-setup.sh [options]
#   --camera        Add camera permissions
#   --photos        Add photo library permissions
#   --notifications Add push notification permissions
#   --location      Add location permissions
#   --tracking      Add app tracking transparency (ATT)
#   --google-signin Add Google Sign-In URL scheme
#   --all           Add all permissions
#
# Example: ./scripts/permissions-setup.sh --camera --photos --notifications
# =============================================================================

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Paths
IOS_PLIST="ios/Runner/Info.plist"
ANDROID_MANIFEST="android/app/src/main/AndroidManifest.xml"

# Check if running from project root
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Run this script from the Flutter project root directory${NC}"
    exit 1
fi

# Parse arguments
CAMERA=false
PHOTOS=false
NOTIFICATIONS=false
LOCATION=false
TRACKING=false
GOOGLE_SIGNIN=false

if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 [--camera] [--photos] [--notifications] [--location] [--tracking] [--google-signin] [--all]${NC}"
    echo ""
    echo "Options:"
    echo "  --camera        Camera access for photos/videos"
    echo "  --photos        Photo library read/write access"
    echo "  --notifications Push notifications"
    echo "  --location      GPS location access"
    echo "  --tracking      App Tracking Transparency (iOS)"
    echo "  --google-signin Google Sign-In URL scheme"
    echo "  --all           Enable all permissions"
    exit 0
fi

for arg in "$@"; do
    case $arg in
        --camera) CAMERA=true ;;
        --photos) PHOTOS=true ;;
        --notifications) NOTIFICATIONS=true ;;
        --location) LOCATION=true ;;
        --tracking) TRACKING=true ;;
        --google-signin) GOOGLE_SIGNIN=true ;;
        --all)
            CAMERA=true
            PHOTOS=true
            NOTIFICATIONS=true
            LOCATION=true
            TRACKING=true
            ;;
    esac
done

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📱 Permissions Setup${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# =============================================================================
# iOS Info.plist modifications
# =============================================================================

add_ios_permission() {
    local key="$1"
    local value="$2"

    # Check if key already exists
    if grep -q "<key>$key</key>" "$IOS_PLIST"; then
        echo -e "  ${YELLOW}⚠${NC} iOS: $key already exists, skipping"
        return
    fi

    # Add before </dict></plist>
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|</dict>|	<key>$key</key>\n	<string>$value</string>\n</dict>|" "$IOS_PLIST"
    else
        sed -i "s|</dict>|	<key>$key</key>\n	<string>$value</string>\n</dict>|" "$IOS_PLIST"
    fi
    echo -e "  ${GREEN}✓${NC} iOS: Added $key"
}

add_ios_array() {
    local key="$1"
    shift
    local values=("$@")

    if grep -q "<key>$key</key>" "$IOS_PLIST"; then
        echo -e "  ${YELLOW}⚠${NC} iOS: $key already exists, skipping"
        return
    fi

    local array_content="<array>"
    for val in "${values[@]}"; do
        array_content="$array_content\n		<string>$val</string>"
    done
    array_content="$array_content\n	</array>"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|</dict>|	<key>$key</key>\n	$array_content\n</dict>|" "$IOS_PLIST"
    else
        sed -i "s|</dict>|	<key>$key</key>\n	$array_content\n</dict>|" "$IOS_PLIST"
    fi
    echo -e "  ${GREEN}✓${NC} iOS: Added $key"
}

# =============================================================================
# Android Manifest modifications
# =============================================================================

add_android_permission() {
    local permission="$1"

    if grep -q "android.permission.$permission" "$ANDROID_MANIFEST"; then
        echo -e "  ${YELLOW}⚠${NC} Android: $permission already exists, skipping"
        return
    fi

    # Add after existing permissions
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|<application|    <uses-permission android:name=\"android.permission.$permission\"/>\n\n    <application|" "$ANDROID_MANIFEST"
    else
        sed -i "s|<application|    <uses-permission android:name=\"android.permission.$permission\"/>\n\n    <application|" "$ANDROID_MANIFEST"
    fi
    echo -e "  ${GREEN}✓${NC} Android: Added $permission"
}

# =============================================================================
# Apply permissions based on flags
# =============================================================================

if [ "$CAMERA" = true ]; then
    echo -e "${CYAN}📷 Adding Camera permissions...${NC}"
    add_ios_permission "NSCameraUsageDescription" "This app needs camera access to take photos and videos."
    add_android_permission "CAMERA"
    echo ""
fi

if [ "$PHOTOS" = true ]; then
    echo -e "${CYAN}🖼️  Adding Photo Library permissions...${NC}"
    add_ios_permission "NSPhotoLibraryUsageDescription" "This app needs access to your photo library to select images."
    add_ios_permission "NSPhotoLibraryAddUsageDescription" "This app needs access to save images to your photo library."
    add_android_permission "READ_EXTERNAL_STORAGE"
    add_android_permission "WRITE_EXTERNAL_STORAGE"
    add_android_permission "READ_MEDIA_IMAGES"
    add_android_permission "READ_MEDIA_VIDEO"
    echo ""
fi

if [ "$NOTIFICATIONS" = true ]; then
    echo -e "${CYAN}🔔 Adding Push Notification permissions...${NC}"
    add_ios_array "UIBackgroundModes" "remote-notification" "fetch"
    add_android_permission "POST_NOTIFICATIONS"
    add_android_permission "RECEIVE_BOOT_COMPLETED"
    add_android_permission "VIBRATE"
    echo ""
fi

if [ "$LOCATION" = true ]; then
    echo -e "${CYAN}📍 Adding Location permissions...${NC}"
    add_ios_permission "NSLocationWhenInUseUsageDescription" "This app needs location access to provide location-based features."
    add_ios_permission "NSLocationAlwaysAndWhenInUseUsageDescription" "This app needs location access to provide location-based features."
    add_android_permission "ACCESS_FINE_LOCATION"
    add_android_permission "ACCESS_COARSE_LOCATION"
    add_android_permission "ACCESS_BACKGROUND_LOCATION"
    echo ""
fi

if [ "$TRACKING" = true ]; then
    echo -e "${CYAN}📊 Adding App Tracking Transparency...${NC}"
    add_ios_permission "NSUserTrackingUsageDescription" "This app would like to track your activity to provide personalized ads."
    echo -e "  ${YELLOW}ℹ${NC}  Android: No equivalent permission needed"
    echo ""
fi

if [ "$GOOGLE_SIGNIN" = true ]; then
    echo -e "${CYAN}🔑 Adding Google Sign-In URL scheme...${NC}"
    echo -e "  ${YELLOW}ℹ${NC}  Google Sign-In URL scheme is auto-configured by flutterfire configure"
    echo -e "  ${YELLOW}ℹ${NC}  Make sure to run: flutterfire configure --project=YOUR_PROJECT_ID"
    echo ""
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Permissions setup completed!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Next steps:"
echo -e "  1. Review changes in ${CYAN}$IOS_PLIST${NC}"
echo -e "  2. Review changes in ${CYAN}$ANDROID_MANIFEST${NC}"
echo -e "  3. Run ${CYAN}flutter clean && flutter pub get${NC}"
echo -e "  4. Rebuild your app"
