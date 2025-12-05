#!/bin/bash

###############################################################################
# Theme Usage Checker Script
###############################################################################
# 
# This script checks which UI Dart files (screens, pages, widgets, components)
# don't use AppTheme or import app_theme.dart, helping identify files that
# may not have dark mode support.
#
# Usage:
#   ./check_theme_usage.sh
#
# The script will:
#   - Check all UI files in lib/screens, lib/pages, lib/widgets, lib/components
#   - Look for AppTheme usage or app_theme.dart imports
#   - Also checks for Theme.of(context) usage (indicates theme awareness)
#   - Excludes models, services, configs, providers, utils, mixins
#   - Outputs a list of files that may need dark mode support
#   - Saves results to files_without_theme.txt
#
# Exit codes:
#   0 - All UI files have theme support
#   1 - Some files are missing theme support
#
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Checking UI Dart files for AppTheme usage...${NC}\n"

# Directories to exclude (test files, generated files, etc.)
EXCLUDE_DIRS="test|build|.dart_tool|.idea|.vscode"

# Files to exclude
EXCLUDE_FILES="app_theme.dart|generated|*.g.dart|*.freezed.dart"

# Only check UI-related files (screens, pages, widgets, components)
# Exclude: models, services, configs, providers, utils, mixins
UI_PATTERNS="screens|pages|widgets|components"
EXCLUDE_PATTERNS="models|services|config|providers|utils|mixins|data"

# Counter
TOTAL_FILES=0
FILES_WITHOUT_THEME=0
FILES_WITH_THEME=0

# Arrays to store files
declare -a FILES_MISSING_THEME
declare -a FILES_WITH_THEME_LIST

# Find all Dart files in lib directory
while IFS= read -r -d '' file; do
    # Skip excluded directories and files
    if [[ "$file" =~ ($EXCLUDE_DIRS) ]] || [[ "$file" =~ ($EXCLUDE_FILES) ]]; then
        continue
    fi
    
    # Only process UI files (screens, pages, widgets, components)
    if [[ ! "$file" =~ ($UI_PATTERNS) ]]; then
        continue
    fi
    
    # Skip if it's in an excluded pattern directory
    if [[ "$file" =~ ($EXCLUDE_PATTERNS) ]]; then
        continue
    fi
    
    TOTAL_FILES=$((TOTAL_FILES + 1))
    
    # Check if file contains AppTheme (case-insensitive) or app_theme import
    # Also check for Theme.of(context) usage which indicates theme awareness
    if grep -qi "apptheme\|app_theme" "$file" || \
       grep -q "import.*app_theme" "$file" || \
       grep -q "import.*AppTheme" "$file" || \
       grep -q "from.*app_theme" "$file" || \
       grep -q "Theme\.of" "$file"; then
        FILES_WITH_THEME=$((FILES_WITH_THEME + 1))
        FILES_WITH_THEME_LIST+=("$file")
    else
        FILES_WITHOUT_THEME=$((FILES_WITHOUT_THEME + 1))
        FILES_MISSING_THEME+=("$file")
    fi
done < <(find lib -name "*.dart" -type f -print0 2>/dev/null)

# Print summary
echo -e "${GREEN}✅ UI files with theme support: ${FILES_WITH_THEME}${NC}"
echo -e "${RED}❌ UI files without theme support: ${FILES_WITHOUT_THEME}${NC}"
echo -e "${BLUE}📊 Total UI files checked: ${TOTAL_FILES}${NC}\n"

# Show some files with theme support as examples
if [ ${#FILES_WITH_THEME_LIST[@]} -gt 0 ] && [ ${#FILES_MISSING_THEME[@]} -gt 0 ]; then
    echo -e "${CYAN}📋 Sample files WITH theme support:${NC}"
    for file in "${FILES_WITH_THEME_LIST[@]:0:5}"; do
        echo -e "  ${GREEN}✓${NC} $file"
    done
    if [ ${#FILES_WITH_THEME_LIST[@]} -gt 5 ]; then
        echo -e "  ${CYAN}... and $(( ${#FILES_WITH_THEME_LIST[@]} - 5 )) more${NC}"
    fi
    echo ""
fi

# Print files without theme
if [ ${#FILES_MISSING_THEME[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Files that may need dark mode support:${NC}\n"
    for file in "${FILES_MISSING_THEME[@]}"; do
        echo -e "  ${RED}•${NC} $file"
    done
    echo ""
    
    # Save to file
    OUTPUT_FILE="files_without_theme.txt"
    printf '%s\n' "${FILES_MISSING_THEME[@]}" > "$OUTPUT_FILE"
    echo -e "${BLUE}📝 List saved to: ${OUTPUT_FILE}${NC}\n"
    
    exit 1
else
    echo -e "${GREEN}✨ All files appear to have theme support!${NC}\n"
    exit 0
fi
