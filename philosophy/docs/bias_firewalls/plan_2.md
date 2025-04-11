
# File: scripts/firewall/bias_watch.sh
```bash
#!/bin/bash

# 1. Cognitive Bias Detector
echo "🔍 Scanning for biased language patterns..."
find . -type f \( -name "*.md" -o -name "*.py" \) | while read file; do
  # Confirmation bias
  grep -qE '\b(obviously|clearly|evidently)\b' "$file" && 
    echo "⚠️ Confirmation bias marker in $file: $(grep -Eo '\b(obviously|clearly|evidently)\b' "$file")"
  
  # Overconfidence patterns
  grep -qE '\b(always|never|impossible)\b' "$file" && 
    echo "⚠️ Absolute claim detected in $file: $(grep -Eo '\b(always|never|impossible)\b' "$file")"
done

# 2. Documentation-Code Cross-Check
echo "⚖️ Verifying documentation/code consistency..."
grep -R "TODO: Update docs" . | while read line; do
  echo "❌ Documentation debt detected: $line"
done

# 3. Mutation Safeguard
echo "🛡️ Checking critical file integrity..."
find . -type f \( -name "*.md" -o -name "*.sh" \) | while read file; do
  current_hash=$(sha256sum "$file" | awk '{print $1}')
  stored_hash=$(grep "$file" .file_hashes 2>/dev/null | awk '{print $2}')
  
  if [ "$current_hash" != "$stored_hash" ] && [ -n "$stored_hash" ]; then
    echo "🚨 Unauthorized change detected in $file"
  fi
done > .file_hashes.tmp
mv .file_hashes.tmp .file_hashes

# 4. Entropy Validator
echo "📊 Checking value distributions..."
awk '/FSM_WEIGHT/{sum+=$2; count++} 
  END{if(count>0 && (sum/count < 0.4 || sum/count > 0.8)){ 
    print "⚠️ Suspicious FSM weight distribution: " sum/count
  }}' philosophy/entropy_index/*/input_manifest.txt
```

**Pre-Commit Hook Integration**:
```bash
# .git/hooks/pre-commit
#!/bin/bash

echo "🔥 Starting bias resistance checks..."

# Run all firewall checks
./scripts/firewall/bias_watch.sh
./scripts/firewall/check_trace_integrity.sh --strict

# Simple documentation linter
grep -R "# TODO" docs/ && { 
  echo "❌ Unresolved documentation TODOs"; 
  exit 1; 
}

# Commit block on findings
if [ $? -ne 0 ]; then
  echo "❌ Commit blocked due to potential bias risks"
  exit 1
fi
```

**Key Features**:
1. **Language Pattern Scanner**  
   - Detects absolutist claims and confirmation bias markers
   - Uses simple regex patterns anyone can modify

2. **Documentation-Code Sync**  
   - Flags "TODO: Update docs" comments
   - Ensures code changes have documentation counterparts

3. **File Integrity Monitor**  
   - Tracks unexpected changes to critical files
   - Uses SHA-256 hashes stored in `.file_hashes`

4. **Distribution Checks**  
   - Flags statistically unlikely FSM_WEIGHT clusters
   - Simple arithmetic checks for value consistency

**Usage**:
```bash
# Initial setup
chmod +x scripts/firewall/*.sh
./scripts/firewall/bias_watch.sh --init  # Creates .file_hashes

# Daily workflow
git commit -m "Update system"  # Automatically runs all checks
```

**Maintenance**:
- Add new bias patterns to `bias_watch.sh` regex
- Update `.file_hashes` when intentionally changing files
- Review flagged items in pre-commit output

This system creates **personal accountability loops** while maintaining simplicity through:
- Plain text pattern matching
- Basic arithmetic checks
- Clear error messages with file/line context

The solo developer remains the ultimate authority but must consciously override flagged items, creating a "bias speed bump" in the workflow.