#!/bin/bash

# JSON-specific test helper functions

# Create a properly formatted status.json file
create_status_json() {
    local project_name="$1"
    local status="${2:-active}"
    local completion="${3:-0}"
    local summary="${4:-Test project}"
    local created_date="${5:-$(date '+%Y-%m-%d %H:%M:%S')}"
    local updated_date="${6:-$(date '+%Y-%m-%d %H:%M:%S')}"
    
    cat << EOF
{
  "project": "$project_name",
  "created": "$created_date",
  "status": "$status",
  "completion_percent": $completion,
  "last_updated": "$updated_date",
  "summary": "$summary"
}
EOF
}

# Assert JSON file contains specific keys/values
assert_json_contains() {
    local file="$1"
    local key="$2"
    local expected_value="$3"
    
    local actual_value=$(jq -r ".$key" "$file" 2>/dev/null)
    if [[ "$actual_value" == "null" ]]; then
        echo "JSON file $file does not contain key: $key" >&2
        return 1
    fi
    if [[ -n "$expected_value" ]]; then
        [[ "$actual_value" == "$expected_value" ]] || { echo "JSON file $file key $key has value '$actual_value', expected '$expected_value'" >&2; return 1; }
    fi
}

# Extract values from JSON files
parse_json_value() {
    local file="$1"
    local key="$2"
    
    jq -r ".$key" "$file" 2>/dev/null || echo ""
}

# Assert JSON file is valid
assert_valid_json() {
    local file="$1"
    
    jq empty "$file" 2>/dev/null || { echo "JSON file $file is not valid JSON" >&2; return 1; }
}

# Create a JSON array from values
create_json_array() {
    local array_items=("$@")
    local result="["
    local first=true
    
    for item in "${array_items[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            result+=","
        fi
        result+="\"$item\""
    done
    
    result+="]"
    echo "$result"
}