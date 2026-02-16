#!/bin/bash

# Script to update the app name from .env file
ENV_FILE="../.env"

echo "=== Updating app name from .env file ==="
echo "Looking for .env file at: $ENV_FILE"

if [ -f "$ENV_FILE" ]; then
    echo ".env file found"
    
    # Extract APP_NAME from .env file
    APP_NAME=$(grep -E '^APP_NAME=' "$ENV_FILE" | cut -d'=' -f2-)
    
    echo "Raw APP_NAME value from .env: $APP_NAME"
    
    # Remove surrounding quotes if present
    if [[ "$APP_NAME" == \"*\" ]] || [[ "$APP_NAME" == \'*\' ]]; then
        APP_NAME=$(echo "$APP_NAME" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\(.*\)'$/\1/")
        echo "APP_NAME after quote removal: $APP_NAME"
    fi
    
    if [ -n "$APP_NAME" ]; then
        echo "APP_NAME to be used: $APP_NAME"
        echo "APP_NAME value is available for both Android and iOS builds"
        
        # Check if this is running on macOS (iOS build environment) by checking for PlistBuddy
        if command -v /usr/libexec/PlistBuddy &> /dev/null; then
            echo "PlistBuddy found - running on macOS, updating iOS Info.plist"
            
            # For iOS on macOS - update Info.plist
            INFO_PLIST_FILE="./Runner/Info.plist"
            if [ -f "$INFO_PLIST_FILE" ]; then
                /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName '$APP_NAME'" "$INFO_PLIST_FILE"
                echo "Updated iOS CFBundleDisplayName to: $APP_NAME"
                
                /usr/libexec/PlistBuddy -c "Set :CFBundleName '$APP_NAME'" "$INFO_PLIST_FILE"
                echo "Updated iOS CFBundleName to: $APP_NAME"
                
                # Show the updated values
                echo "Current iOS CFBundleDisplayName: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$INFO_PLIST_FILE" 2>/dev/null)"
                echo "Current iOS CFBundleName: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$INFO_PLIST_FILE" 2>/dev/null)"
            else
                echo "Info.plist file not found at: $INFO_PLIST_FILE - this is expected if running in Android environment"
            fi
        else
            echo "PlistBuddy not found - likely running in Linux environment for Android"
            echo "APP_NAME will be handled by Android build system (build.gradle.kts)"
        fi
    else
        echo "APP_NAME not found or empty in .env file"
        echo "Contents of .env file:"
        cat "$ENV_FILE"
    fi
else
    echo ".env file not found at $ENV_FILE"
    echo "Current directory: $(pwd)"
    echo "Contents of parent directory:"
    ls -la ..
    exit 1
fi

echo "=== App name update completed ==="