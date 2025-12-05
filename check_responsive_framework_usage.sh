#!/bin/bash

# Script to check if all Dart UI files use responsive_framework
# Usage: ./check_responsive_framework_usage.sh

echo "🔍 Checking Dart UI files for responsive_framework usage..."
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories to check (UI-related files only)
UI_DIRS=(
  "lib/screens"
  "lib/pages"
  "lib/widgets"
  "lib/components"
)

# Patterns to exclude (non-UI files)
EXCLUDE_PATTERNS=(
  "models"
  "services"
  "config"
  "providers"
  "utils"
  "mixins"
  "data"
  "*.g.dart"
  "*.freezed.dart"
)

# Find all Dart files in UI directories
FILES=()
for dir in "${UI_DIRS[@]}"; do
  if [ -d "$dir" ]; then
    while IFS= read -r -d '' file; do
      # Check if file should be excluded
      should_exclude=false
      for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
          should_exclude=true
          break
        fi
      done
      
      if [ "$should_exclude" = false ]; then
        FILES+=("$file")
      fi
    done < <(find "$dir" -name "*.dart" -type f -print0 2>/dev/null)
  fi
done

# Counters
TOTAL_FILES=${#FILES[@]}
FILES_WITH_RESPONSIVE=0
FILES_WITHOUT_RESPONSIVE=0
FILES_WITH_IMPORT=0
FILES_WITH_USAGE=0

# Arrays to store results
FILES_WITHOUT=()
FILES_WITH_IMPORT_ONLY=()

# Check each file
for file in "${FILES[@]}"; do
  # Check for responsive_framework import
  has_import=false
  has_usage=false
  
  if grep -q "responsive_framework" "$file" 2>/dev/null; then
    has_import=true
    FILES_WITH_IMPORT=$((FILES_WITH_IMPORT + 1))
  fi
  
  # Check for responsive_framework usage patterns
  if grep -qE "(ResponsiveWrapper|ResponsiveBreakpoints|ResponsiveValue|ResponsiveVisibility|ResponsiveScaledBox|Breakpoints|\.responsive)" "$file" 2>/dev/null; then
    has_usage=true
    FILES_WITH_USAGE=$((FILES_WITH_USAGE + 1))
  fi
  
  # File has responsive_framework if it has import OR usage
  if [ "$has_import" = true ] || [ "$has_usage" = true ]; then
    FILES_WITH_RESPONSIVE=$((FILES_WITH_RESPONSIVE + 1))
  else
    FILES_WITHOUT_RESPONSIVE=$((FILES_WITHOUT_RESPONSIVE + 1))
    FILES_WITHOUT+=("$file")
  fi
  
  # Check if file has import but no usage
  if [ "$has_import" = true ] && [ "$has_usage" = false ]; then
    FILES_WITH_IMPORT_ONLY+=("$file")
  fi
done

# Print results
echo -e "${BLUE}📊 Results:${NC}"
echo -e "${GREEN}✅ Files with responsive_framework: $FILES_WITH_RESPONSIVE${NC}"
echo -e "${YELLOW}📦 Files with import only: $FILES_WITH_IMPORT${NC}"
echo -e "${GREEN}🔧 Files with usage: $FILES_WITH_USAGE${NC}"
echo -e "${RED}❌ Files without responsive_framework: $FILES_WITHOUT_RESPONSIVE${NC}"
echo -e "${BLUE}📊 Total UI files checked: $TOTAL_FILES${NC}"
echo ""

# List files without responsive_framework
if [ ${#FILES_WITHOUT[@]} -gt 0 ]; then
  echo -e "${RED}❌ Files without responsive_framework:${NC}"
  for file in "${FILES_WITHOUT[@]}"; do
    echo "  - $file"
  done
  echo ""
fi

# List files with import but no usage
if [ ${#FILES_WITH_IMPORT_ONLY[@]} -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Files with import but no usage:${NC}"
  for file in "${FILES_WITH_IMPORT_ONLY[@]}"; do
    echo "  - $file"
  done
  echo ""
fi

# Summary
if [ $FILES_WITHOUT_RESPONSIVE -eq 0 ]; then
  echo -e "${GREEN}✨ All files appear to use responsive_framework!${NC}"
  exit 0
else
  echo -e "${YELLOW}💡 Consider adding responsive_framework to the files listed above.${NC}"
  exit 1
fi
