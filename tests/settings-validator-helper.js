#!/usr/bin/env node
// SPDX-License-Identifier: PolyForm-Shield-1.0.0
// Copyright (c) 2025-present Richard Mann
// Licensed under the PolyForm Shield License 1.0.0
// https://polyformproject.org/licenses/shield/1.0.0/

const fs = require('fs');
const path = require('path');

// Load settings.json
const settingsPath = path.join(__dirname, '../assets/.claude/settings.json');
const settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));

// Extract deny patterns
const denyPatterns = settings.permissions.deny || [];

// Convert glob pattern to regex
function globToRegex(pattern) {
    // Extract the path pattern from "Read(...)" format
    const match = pattern.match(/^Read\((.*)\)$/);
    if (!match) {
        throw new Error(`Invalid pattern format: ${pattern}`);
    }
    
    let pathPattern = match[1];
    
    // Escape special regex characters except * and /
    pathPattern = pathPattern.replace(/[.+?^${}()|[\]\\]/g, '\\$&');
    
    // Convert ** to match any directory depth (including empty)
    pathPattern = pathPattern.replace(/\*\*/g, '(?:.*/)?');
    
    // Convert remaining * to match any characters except /
    pathPattern = pathPattern.replace(/\*/g, '[^/]*');
    
    // Ensure the pattern matches the end of the path
    return new RegExp(pathPattern + '$');
}

// Test if a file path matches any deny pattern
function testPath(filePath) {
    for (const pattern of denyPatterns) {
        const regex = globToRegex(pattern);
        if (regex.test(filePath)) {
            return {
                denied: true,
                matchedPattern: pattern,
                regex: regex.toString()
            };
        }
    }
    return {
        denied: false,
        matchedPattern: null,
        regex: null
    };
}

// Main function
function main() {
    const args = process.argv.slice(2);
    
    if (args.length === 0) {
        console.error('Usage: settings-validator-helper.js <file-path>');
        console.error('   or: settings-validator-helper.js --show-patterns');
        process.exit(1);
    }
    
    if (args[0] === '--show-patterns') {
        console.log('Deny patterns in settings.json:');
        denyPatterns.forEach((pattern, index) => {
            console.log(`  ${index + 1}. ${pattern}`);
        });
        process.exit(0);
    }
    
    const filePath = args[0];
    const result = testPath(filePath);
    
    if (result.denied) {
        console.log(`DENIED: ${filePath}`);
        console.log(`Matched pattern: ${result.matchedPattern}`);
        console.log(`Regex: ${result.regex}`);
        process.exit(1); // Exit with error code to indicate denial
    } else {
        console.log(`ALLOWED: ${filePath}`);
        console.log('No deny patterns matched');
        process.exit(0); // Exit with success code to indicate allowed
    }
}

// Run the main function
main();