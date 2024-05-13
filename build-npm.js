#!/usr/bin/env node
const args = process.argv.slice(2);

const {execFileSync} = require('child_process')
const fs = require("fs");
const stdio = ["inherit", "inherit", "inherit"];

if (args[0] === 'npm:final') {
    
} else if (args[0] === 'publish:npm') {
    execFileSync("npm", ["publish"], {stdio});
} else if (args[0] === 'publish') {
    execFileSync("cargo", ["install", "cargo-release"], {stdio});
    execFileSync("cargo", ["release", "--execute"], {stdio});
    execFileSync("npm", ["publish", "--tag", "rc"], {stdio});
} else {
    execFileSync("cargo", ["build"], {stdio});
}