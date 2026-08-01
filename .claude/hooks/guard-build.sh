#!/bin/sh
#
# PreToolUse(Bash) guard — refuse unbounded Swift/Xcode builds.
#
# This machine has 8 GB of RAM. xcodebuild without -jobs spawns one
# swift-frontend per core, each with no memory ceiling of its own. On
# 2026-08-02 three of them held ~52 GB, exhausted the VM compressor, starved
# WindowServer past its 120s watchdog, and kernel-panicked the Mac three times
# (/Library/Logs/DiagnosticReports/Retired/panic-full-2026-08-02-*.panic).
#
# ~/bin/memguard.sh is the backstop that kills runaways. This is the front stop
# that keeps them from being spawned in the first place.

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')

[ -z "$cmd" ] && exit 0

# Only build drivers. Never `swift --version`, `xcrun simctl`, `xcodebuild -list`.
echo "$cmd" | grep -qE '(xcodebuild|swiftc|swift +build)' || exit 0
echo "$cmd" | grep -qE 'xcodebuild +-(list|showsdks|version)' && exit 0

deny() {
    jq -n --arg r "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $r
        }
    }'
    exit 0
}

# 1. Concurrency must be capped. Unbounded fan-out is what panics the machine.
echo "$cmd" | grep -qE -- '-(jobs|j)[ =]+[0-9]+' || \
    deny "Blocked: no concurrency cap. This Mac has 8 GB RAM and each swift-frontend can reach 15+ GB with no ceiling of its own — unbounded fan-out kernel-panicked it 3x on 2026-08-02. Re-run with '-jobs 1' (or '-jobs 2' at most)."

# 2. Derived data must live outside the iCloud-synced Desktop, or codesign
#    fails on the xattrs iCloud attaches. Long-standing rule for this repo.
if echo "$cmd" | grep -q 'xcodebuild'; then
    echo "$cmd" | grep -q -- '-derivedDataPath' || \
        deny "Blocked: xcodebuild without -derivedDataPath. The default location is under the iCloud-synced Desktop, where codesign fails on iCloud's xattrs. Point it at the scratchpad or /tmp."

    echo "$cmd" | grep -qiE -- '-derivedDataPath +[^ ]*(Desktop|Documents)' && \
        deny "Blocked: -derivedDataPath points into an iCloud-synced folder (Desktop/Documents). codesign fails on the xattrs iCloud attaches there. Use the scratchpad or /tmp."
fi

exit 0
