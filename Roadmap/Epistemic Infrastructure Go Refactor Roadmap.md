# Epistemic Infrastructure Go Refactor Roadmap

## Phase 1: Go Core Migration (Commit 1)

### Step 1.1: Project Structure
```
epistemic/
├── cmd/
│   └── epistemic/
│       └── main.go                 # CLI entry point
├── pkg/
│   ├── trace/
│   │   ├── artifact.go            # Artifact trace types
│   │   ├── system.go              # System trace types
│   │   ├── encoder.go             # encode_artifact logic
│   │   └── generator.go           # generate_entropy_trace logic
│   ├── manifest/
│   │   ├── types.go               # Manifest structures
│   │   ├── parser.go              # Parse input_manifest.txt
│   │   └── validator.go           # Field validation
│   ├── hash/
│   │   ├── hasher.go              # SHA-256 operations
│   │   └── comparison.go          # Hamming distance
│   ├── quarantine/
│   │   ├── scanner.go             # scan_unencoded_artifacts
│   │   └── manager.go             # Quarantine operations
│   └── validation/
│       ├── integrity.go           # check_trace_integrity
│       ├── boundary.go            # Domain contamination checks
│       └── lineage.go             # Generational validation
├── internal/
│   └── config/
│       └── config.go              # Global configuration
├── go.mod
└── go.sum
```

### Step 1.2: Core Types
```go
// pkg/trace/types.go
package trace

import "time"

type Manifest struct {
    FSMWeight     float64   `yaml:"FSM_WEIGHT"`
    Tension       float64   `yaml:"Tension"`
    CollapseLog   int       `yaml:"Collapse_Log"`
    Generation    string    `yaml:"Generation"`
    Timestamp     time.Time `yaml:"Timestamp"`
}

type Trace struct {
    ID           string
    Generation   int
    Domain       DomainType // artifact or system
    Path         string
    Manifest     Manifest
    Hash         string
    RawContent   []byte
}

type DomainType int

const (
    DomainArtifact DomainType = iota
    DomainSystem
)

type ValidationResult struct {
    Passed   bool
    Severity Severity
    Issues   []Issue
}

type Issue struct {
    Severity  Severity
    Category  string
    Message   string
    Hash      string
    Timestamp time.Time
}

type Severity int

const (
    SeverityInfo Severity = iota
    SeverityWarning
    SeverityCritical
)
```

### Step 1.3: Migration Priority
1. **Hash operations** (simplest, no dependencies)
2. **Manifest parsing** (file I/O, YAML parsing)
3. **Trace encoding** (combines hash + manifest)
4. **Validation logic** (boundary checks, lineage)
5. **CLI commands** (cobra/urfave for subcommands)

### Step 1.4: CLI Interface
```bash
epistemic encode <file>              # Replace encode_artifact.sh
epistemic trace <role> <gen>         # Replace generate_entropy_trace.sh
epistemic scan                       # Replace scan_unencoded_artifacts.sh
epistemic validate [--strict]        # Replace check_trace_integrity.sh
epistemic compare <trace1> <trace2>  # New: structured comparison
```

---

## Phase 2: Qualitative Epistemics Layer (Commit 2)

### Step 2.1: Belief Tracking Types
```go
// pkg/epistemics/belief.go
package epistemics

import "time"

type Claim struct {
    ID          string
    Text        string
    Confidence  float64      // 0.0 - 1.0
    Evidence    []Evidence
    Created     time.Time
    LastUpdated time.Time
    TraceRef    string       // Links to trace hash
}

type Evidence struct {
    Type        EvidenceType
    Description string
    Weight      float64      // Impact on confidence
    Source      string
    Timestamp   time.Time
}

type EvidenceType int

const (
    EvidenceSupporting EvidenceType = iota
    EvidenceContradicting
    EvidenceNeutral
)

type BeliefUpdate struct {
    ClaimID        string
    PriorConfidence float64
    PosteriorConfidence float64
    Reason         string
    Evidence       Evidence
    Timestamp      time.Time
}
```

### Step 2.2: Simple Bayesian Updater
```go
// pkg/epistemics/bayesian.go
package epistemics

import "math"

type BayesianUpdater struct {
    priorAlpha float64 // Beta distribution α
    priorBeta  float64 // Beta distribution β
}

func NewBayesianUpdater(initialConfidence float64) *BayesianUpdater {
    // Convert confidence to beta parameters
    // Using method of moments with assumed sample size of 10
    n := 10.0
    alpha := initialConfidence * n
    beta := (1 - initialConfidence) * n
    
    return &BayesianUpdater{
        priorAlpha: alpha,
        priorBeta:  beta,
    }
}

func (b *BayesianUpdater) Update(evidence Evidence) float64 {
    // Simple beta-binomial update
    if evidence.Type == EvidenceSupporting {
        b.priorAlpha += evidence.Weight
    } else if evidence.Type == EvidenceContradicting {
        b.priorBeta += evidence.Weight
    }
    
    // Return updated mean of beta distribution
    return b.priorAlpha / (b.priorAlpha + b.priorBeta)
}

func (b *BayesianUpdater) Confidence() float64 {
    return b.priorAlpha / (b.priorAlpha + b.priorBeta)
}

func (b *BayesianUpdater) Uncertainty() float64 {
    // Standard deviation of beta distribution
    a, b := b.priorAlpha, b.priorBeta
    variance := (a * b) / ((a + b) * (a + b) * (a + b + 1))
    return math.Sqrt(variance)
}
```

### Step 2.3: Claim Extraction
```go
// pkg/epistemics/extractor.go
package epistemics

import (
    "regexp"
    "strings"
)

type ClaimExtractor struct {
    patterns []*regexp.Regexp
}

func NewClaimExtractor() *ClaimExtractor {
    return &ClaimExtractor{
        patterns: []*regexp.Regexp{
            // Catch explicit claims
            regexp.MustCompile(`(?i)I claim that (.+)`),
            regexp.MustCompile(`(?i)It is the case that (.+)`),
            regexp.MustCompile(`(?i)(?:Therefore|Thus|Hence), (.+)`),
            
            // Catch modal claims
            regexp.MustCompile(`(?i)(.+) (?:must|should|ought to) (.+)`),
            
            // Catch causal claims
            regexp.MustCompile(`(?i)(.+) (?:causes|leads to|results in) (.+)`),
        },
    }
}

func (e *ClaimExtractor) Extract(text string) []Claim {
    var claims []Claim
    lines := strings.Split(text, "\n")
    
    for _, line := range lines {
        for _, pattern := range e.patterns {
            if matches := pattern.FindStringSubmatch(line); matches != nil {
                claim := Claim{
                    ID:         generateClaimID(line),
                    Text:       strings.TrimSpace(matches[1]),
                    Confidence: 0.5, // Default uncertain
                    Created:    time.Now(),
                }
                claims = append(claims, claim)
            }
        }
    }
    
    return claims
}
```

### Step 2.4: CLI Integration
```bash
epistemic claims extract <file>           # Extract claims from markdown
epistemic claims update <id> --evidence   # Add evidence to claim
epistemic claims show <id>                # Show claim + belief history
epistemic claims validate                 # Check for contradictions
```

---

## Phase 3: Structural Fixes (Commit 3)

### Step 3.1: Symbolic Drift Metrics
```go
// pkg/drift/symbolic.go
package drift

import (
    "strings"
    "unicode"
)

type DriftMetrics struct {
    JaccardSimilarity    float64
    EditDistance         int
    LogicalDrift         float64
    QuantifierChanges    int
    NegationFlips        int
    ConnectiveChanges    int
    OverallScore         float64
}

// Jaccard similarity (word overlap)
func JaccardSimilarity(text1, text2 string) float64 {
    words1 := tokenize(text1)
    words2 := tokenize(text2)
    
    intersection := intersect(words1, words2)
    union := union(words1, words2)
    
    if len(union) == 0 {
        return 0.0
    }
    
    return float64(len(intersection)) / float64(len(union))
}

// Levenshtein edit distance
func EditDistance(s1, s2 string) int {
    if len(s1) == 0 {
        return len(s2)
    }
    if len(s2) == 0 {
        return len(s1)
    }
    
    // Standard DP algorithm
    dp := make([][]int, len(s1)+1)
    for i := range dp {
        dp[i] = make([]int, len(s2)+1)
        dp[i][0] = i
    }
    for j := range dp[0] {
        dp[0][j] = j
    }
    
    for i := 1; i <= len(s1); i++ {
        for j := 1; j <= len(s2); j++ {
            cost := 0
            if s1[i-1] != s2[j-1] {
                cost = 1
            }
            dp[i][j] = min(
                dp[i-1][j]+1,      // deletion
                dp[i][j-1]+1,      // insertion
                dp[i-1][j-1]+cost, // substitution
            )
        }
    }
    
    return dp[len(s1)][len(s2)]
}

func tokenize(text string) []string {
    return strings.FieldsFunc(strings.ToLower(text), func(r rune) bool {
        return !unicode.IsLetter(r) && !unicode.IsNumber(r)
    })
}

func intersect(a, b []string) []string {
    set := make(map[string]bool)
    for _, item := range a {
        set[item] = true
    }
    
    var result []string
    for _, item := range b {
        if set[item] {
            result = append(result, item)
            delete(set, item) // Avoid duplicates
        }
    }
    return result
}

func union(a, b []string) []string {
    set := make(map[string]bool)
    for _, item := range a {
        set[item] = true
    }
    for _, item := range b {
        set[item] = true
    }
    
    result := make([]string, 0, len(set))
    for item := range set {
        result = append(result, item)
    }
    return result
}

func min(a, b, c int) int {
    if a < b {
        if a < c {
            return a
        }
        return c
    }
    if b < c {
        return b
    }
    return c
}
```

### Step 3.2: Logical Form Parser
```go
// pkg/drift/logical.go
package drift

import (
    "regexp"
    "strings"
)

type LogicalForm int

const (
    FormConditional LogicalForm = iota  // If X then Y
    FormUniversal                       // All X are Y
    FormExistential                     // Some X are Y
    FormNegation                        // Not X
    FormConjunction                     // X and Y
    FormDisjunction                     // X or Y
    FormBiconditional                   // X iff Y
    FormUnknown
)

type LogicalStatement struct {
    Form      LogicalForm
    Subject   string
    Predicate string
    Negated   bool
}

type LogicalParser struct {
    patterns map[LogicalForm]*regexp.Regexp
}

func NewLogicalParser() *LogicalParser {
    return &LogicalParser{
        patterns: map[LogicalForm]*regexp.Regexp{
            FormConditional: regexp.MustCompile(
                `(?i)(?:if|when|given that) (.+?)(?: then|,) (.+)`),
            FormUniversal: regexp.MustCompile(
                `(?i)(?:all|every|each) (.+?) (?:is|are) (.+)`),
            FormExistential: regexp.MustCompile(
                `(?i)(?:some|at least one|there exists?) (.+?) (?:is|are) (.+)`),
            FormNegation: regexp.MustCompile(
                `(?i)(?:not|no|never) (.+)`),
            FormConjunction: regexp.MustCompile(
                `(?i)(.+?) (?:and|both .+ and) (.+)`),
            FormDisjunction: regexp.MustCompile(
                `(?i)(.+?) (?:or|either .+ or) (.+)`),
            FormBiconditional: regexp.MustCompile(
                `(?i)(.+?) (?:if and only if|iff) (.+)`),
        },
    }
}

func (p *LogicalParser) Parse(text string) []LogicalStatement {
    var statements []LogicalStatement
    
    for form, pattern := range p.patterns {
        if matches := pattern.FindStringSubmatch(text); matches != nil {
            stmt := LogicalStatement{
                Form: form,
            }
            
            if len(matches) > 1 {
                stmt.Subject = strings.TrimSpace(matches[1])
            }
            if len(matches) > 2 {
                stmt.Predicate = strings.TrimSpace(matches[2])
            }
            
            // Check for negation
            negPattern := regexp.MustCompile(`(?i)^(?:not|no|never) `)
            if negPattern.MatchString(text) {
                stmt.Negated = true
            }
            
            statements = append(statements, stmt)
        }
    }
    
    return statements
}

// Compare logical forms between two texts
func CompareLogicalForms(text1, text2 string) DriftMetrics {
    parser := NewLogicalParser()
    forms1 := parser.Parse(text1)
    forms2 := parser.Parse(text2)
    
    metrics := DriftMetrics{
        JaccardSimilarity: JaccardSimilarity(text1, text2),
        EditDistance:      EditDistance(text1, text2),
    }
    
    // Count structural changes
    for _, f1 := range forms1 {
        matched := false
        for _, f2 := range forms2 {
            if f1.Form == f2.Form {
                matched = true
                // Check for negation flips
                if f1.Negated != f2.Negated {
                    metrics.NegationFlips++
                }
                break
            }
        }
        if !matched {
            // Logical form changed
            metrics.ConnectiveChanges++
        }
    }
    
    // Detect quantifier changes
    quantifiers1 := countQuantifiers(forms1)
    quantifiers2 := countQuantifiers(forms2)
    metrics.QuantifierChanges = abs(quantifiers1[FormUniversal] - quantifiers2[FormUniversal]) +
        abs(quantifiers1[FormExistential] - quantifiers2[FormExistential])
    
    // Compute overall logical drift score
    metrics.LogicalDrift = float64(metrics.NegationFlips + 
        metrics.ConnectiveChanges + 
        metrics.QuantifierChanges) / 10.0
    
    // Combined score (weighted average)
    metrics.OverallScore = (metrics.JaccardSimilarity * 0.3) +
        ((1.0 - metrics.LogicalDrift) * 0.4) +
        (normalizeEditDistance(metrics.EditDistance, len(text1), len(text2)) * 0.3)
    
    return metrics
}

func countQuantifiers(forms []LogicalStatement) map[LogicalForm]int {
    counts := make(map[LogicalForm]int)
    for _, f := range forms {
        if f.Form == FormUniversal || f.Form == FormExistential {
            counts[f.Form]++
        }
    }
    return counts
}

func abs(n int) int {
    if n < 0 {
        return -n
    }
    return n
}

func normalizeEditDistance(distance int, len1, len2 int) float64 {
    maxLen := float64(max(len1, len2))
    if maxLen == 0 {
        return 0.0
    }
    return 1.0 - (float64(distance) / maxLen)
}

func max(a, b int) int {
    if a > b {
        return a
    }
    return b
}
```

### Step 3.3: Enhanced Comparison
```go
// pkg/trace/comparison.go
package trace

import "epistemic/pkg/drift"

type ComparisonResult struct {
    Trace1       *Trace
    Trace2       *Trace
    HashMatch    bool
    DriftMetrics drift.DriftMetrics
    Explanation  string
}

func Compare(t1, t2 *Trace) ComparisonResult {
    result := ComparisonResult{
        Trace1:    t1,
        Trace2:    t2,
        HashMatch: t1.Hash == t2.Hash,
    }
    
    // Compute drift metrics
    result.DriftMetrics = drift.CompareLogicalForms(
        string(t1.RawContent),
        string(t2.RawContent),
    )
    
    // Generate explanation
    if result.HashMatch {
        result.Explanation = "Traces are identical (hash match)"
    } else if result.DriftMetrics.OverallScore > 0.9 {
        result.Explanation = "Minor semantic drift detected"
    } else if result.DriftMetrics.NegationFlips > 0 {
        result.Explanation = "Critical: Negation flips detected"
    } else if result.DriftMetrics.QuantifierChanges > 0 {
        result.Explanation = "Quantifier changes detected"
    } else {
        result.Explanation = "Significant semantic drift"
    }
    
    return result
}
```

### Step 3.4: CLI Integration
```bash
epistemic compare <trace1> <trace2> --detailed  # Show full drift metrics
epistemic drift-report <generation>             # Analyze drift across generations
```

---

## Phase 4: Obsidian Integration (Commit 4)

### Step 4.1: Vault Scanner
```go
// pkg/obsidian/scanner.go
package obsidian

import (
    "io/fs"
    "path/filepath"
    "strings"
)

type Vault struct {
    Path   string
    Name   string
    Files  []string
}

func FindVaults(root string) ([]Vault, error) {
    var vaults []Vault
    
    err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
        if err != nil {
            return err
        }
        
        if d.IsDir() && d.Name() == ".obsidian" {
            vaultPath := filepath.Dir(path)
            vault := Vault{
                Path: vaultPath,
                Name: filepath.Base(vaultPath),
            }
            
            // Find all markdown files
            filepath.WalkDir(vaultPath, func(p string, d fs.DirEntry, err error) error {
                if err != nil {
                    return err
                }
                if !d.IsDir() && strings.HasSuffix(d.Name(), ".md") {
                    vault.Files = append(vault.Files, p)
                }
                return nil
            })
            
            vaults = append(vaults, vault)
            return filepath.SkipDir // Don't recurse into vault
        }
        
        return nil
    })
    
    return vaults, err
}

func (v *Vault) ExtractClaims() ([]epistemics.Claim, error) {
    extractor := epistemics.NewClaimExtractor()
    var allClaims []epistemics.Claim
    
    for _, file := range v.Files {
        content, err := os.ReadFile(file)
        if err != nil {
            continue
        }
        
        claims := extractor.Extract(string(content))
        for i := range claims {
            claims[i].TraceRef = file
        }
        allClaims = append(allClaims, claims...)
    }
    
    return allClaims, nil
}
```

### Step 4.2: Contradiction Detector
```go
// pkg/obsidian/contradiction.go
package obsidian

import (
    "epistemic/pkg/epistemics"
    "epistemic/pkg/drift"
)

type Contradiction struct {
    Claim1    epistemics.Claim
    Claim2    epistemics.Claim
    Severity  float64  // 0.0 - 1.0
    Reason    string
}

func DetectContradictions(claims []epistemics.Claim) []Contradiction {
    var contradictions []Contradiction
    
    // Pairwise comparison
    for i := 0; i < len(claims); i++ {
        for j := i + 1; j < len(claims); j++ {
            c1, c2 := claims[i], claims[j]
            
            // Parse logical forms
            parser := drift.NewLogicalParser()
            forms1 := parser.Parse(c1.Text)
            forms2 := parser.Parse(c2.Text)
            
            // Check for direct negation
            if isNegation(forms1, forms2) {
                contradictions = append(contradictions, Contradiction{
                    Claim1:   c1,
                    Claim2:   c2,
                    Severity: 1.0,
                    Reason:   "Direct logical negation",
                })
                continue
            }
            
            // Check for quantifier contradiction
            if hasQuantifierConflict(forms1, forms2) {
                contradictions = append(contradictions, Contradiction{
                    Claim1:   c1,
                    Claim2:   c2,
                    Severity: 0.8,
                    Reason:   "Quantifier conflict (all vs. some)",
                })
            }
            
            // Check for high semantic similarity with opposite evidence
            metrics := drift.CompareLogicalForms(c1.Text, c2.Text)
            if metrics.JaccardSimilarity > 0.7 && metrics.NegationFlips > 0 {
                contradictions = append(contradictions, Contradiction{
                    Claim1:   c1,
                    Claim2:   c2,
                    Severity: 0.6,
                    Reason:   "High similarity with negation flip",
                })
            }
        }
    }
    
    return contradictions
}

func isNegation(forms1, forms2 []drift.LogicalStatement) bool {
    for _, f1 := range forms1 {
        for _, f2 := range forms2 {
            if f1.Subject == f2.Subject && 
               f1.Predicate == f2.Predicate &&
               f1.Negated != f2.Negated {
                return true
            }
        }
    }
    return false
}

func hasQuantifierConflict(forms1, forms2 []drift.LogicalStatement) bool {
    for _, f1 := range forms1 {
        for _, f2 := range forms2 {
            if f1.Subject == f2.Subject {
                if (f1.Form == drift.FormUniversal && f2.Form == drift.FormExistential) ||
                   (f1.Form == drift.FormExistential && f2.Form == drift.FormUniversal) {
                    return true
                }
            }
        }
    }
    return false
}
```

### Step 4.3: Report Generator
```go
// pkg/obsidian/report.go
package obsidian

import (
    "fmt"
    "os"
    "sort"
    "strings"
    "time"
)

func GenerateReport(vault Vault, contradictions []Contradiction) string {
    var sb strings.Builder
    
    sb.WriteString(fmt.Sprintf("# Epistemic Audit: %s\n\n", vault.Name))
    sb.WriteString(fmt.Sprintf("Generated: %s\n\n", time.Now().Format(time.RFC3339)))
    
    // Sort by severity
    sort.Slice(contradictions, func(i, j int) bool {
        return contradictions[i].Severity > contradictions[j].Severity
    })
    
    sb.WriteString("## Critical Contradictions\n\n")
    for _, c := range contradictions {
        if c.Severity >= 0.8 {
            sb.WriteString(fmt.Sprintf("### Severity: %.2f\n", c.Severity))
            sb.WriteString(fmt.Sprintf("**Reason:** %s\n\n", c.Reason))
            sb.WriteString(fmt.Sprintf("**Claim 1:** %s\n", c.Claim1.Text))
            sb.WriteString(fmt.Sprintf("- File: `%s`\n", c.Claim1.TraceRef))
            sb.WriteString(fmt.Sprintf("- Confidence: %.2f\n\n", c.Claim1.Confidence))
            sb.WriteString(fmt.Sprintf("**Claim 2:** %s\n", c.Claim2.Text))
            sb.WriteString(fmt.Sprintf("- File: `%s`\n", c.Claim2.TraceRef))
            sb.WriteString(fmt.Sprintf("- Confidence: %.2f\n\n", c.Claim2.Confidence))
            sb.WriteString("---\n\n")
        }
    }
    
    sb.WriteString("## Moderate Contradictions\n\n")
    for _, c := range contradictions {
        if c.Severity >= 0.5 && c.Severity < 0.8 {
            sb.WriteString(fmt.Sprintf("- **%s** (%.2f)\n", c.Reason, c.Severity))
            sb.WriteString(fmt.Sprintf("  - `%s` vs `%s`\n", 
                filepath.Base(c.Claim1.TraceRef),
                filepath.Base(c.Claim2.TraceRef)))
        }
    }
    
    return sb.String()
}

func WriteReport(vault Vault, report string) error {
    reportPath := filepath.Join(vault.Path, "epistemic-audit.md")
    return os.WriteFile(reportPath, []byte(report), 0644)
}
```

### Step 4.4: CLI Integration
```bash
epistemic vault scan [path]                    # Find Obsidian vaults
epistemic vault audit <vault-path>             # Run full audit
epistemic vault watch <vault-path>             # Continuous monitoring
epistemic vault report <vault-path> --output   # Generate markdown report
```

### Step 4.5: Interactive Mode
```go
// cmd/epistemic/interactive.go
package main

import (
    "bufio"
    "fmt"
    "os"
    "strings"
)

func interactiveMode() {
    fmt.Println("🧠 Epistemic Infrastructure - Interactive Mode")
    fmt.Println("Type 'help' for commands\n")
    
    scanner := bufio.NewScanner(os.Stdin)
    
    for {
        fmt.Print("> ")
        if !scanner.Scan() {
            break
        }
        
        input := strings.TrimSpace(scanner.Text())
        if input == "" {
            continue
        }
        
        parts := strings.Fields(input)
        cmd := parts[0]
        
        switch cmd {
        case "scan":
            // Auto-detect vaults
            vaults, _ := obsidian.FindVaults(os.Getenv("HOME"))
            fmt.Printf("Found %d vault(s):\n", len(vaults))
            for i, v := range vaults {
                fmt.Printf("%d. %s (%s)\n", i+1, v.Name, v.Path)
            }
            
        case "audit":
            if len(parts) < 2 {
                fmt.Println("Usage: audit <vault-number>")
                continue
            }
            // Run audit on selected vault
            
        case "help":
            printHelp()
            
        case "exit":
            return
            
        default:
            fmt.Printf("Unknown command: %s\n", cmd)
        }
    }
}
```

---

## Testing Strategy

### Unit Tests
```go
// pkg/drift/symbolic_test.go
func TestJaccardSimilarity(t *testing.T) {
    tests := []struct {
        text1    string
        text2    string
        expected float64
    }{
        {"all X are Y", "all X are Y", 1.0},
        {"all X are Y", "some X are Y", 0.75},
        {"X and Y", "X or Y", 0.667},
    }
    
    for _, tt := range tests {
        result := JaccardSimilarity(tt.text1, tt.text2)
        if math.Abs(result-tt.expected) > 0.01 {
            t.Errorf("Expected %.3f, got %.3f", tt.expected, result)
        }
    }
}
```

### Integration Tests
```bash
#!/bin/bash
# test/integration/vault_audit_test.sh

# Setup test vault
mkdir -p test-vault/.obsidian
echo "All LLMs use transformers" > test-vault/claim1.md
echo "Some LLMs don't use transformers" > test-vault/claim2.md

# Run audit
./epistemic vault audit test-vault

# Check for contradiction detection
if grep -q "Quantifier conflict" test-vault/epistemic-audit.md; then
    echo "✅ Contradiction detected"
else
    echo "❌ Test failed"
    exit 1
fi
```

---

## Documentation

### README.md
```markdown
# Epistemic Infrastructure

Immutable contradiction tracking and belief updating for high-stakes reasoning.

## Quick Start

```bash
# Install
go install github.com/yourusername/epistemic@latest

# Scan for Obsidian vaults
epistemic vault scan

# Run audit
epistemic vault audit ~/Documents/MyVault

# View report
cat ~/Documents/MyVault/epistemic-audit.md
```

## Features

- **Immutable Traces**: SHA-256 hashed claims with provenance
- **Contradiction Detection**: Symbolic logic parsing + semantic drift
- **Bayesian Updates**: Automatic confidence adjustment
- **Obsidian Native**: Works with your existing notes
```

---

## Deployment

### Binary Releases
```bash
# Build for multiple platforms
GOOS=linux GOARCH=amd64 go build -o epistemic-linux-amd64
GOOS=darwin GOARCH=amd64 go build -o epistemic-darwin-amd64
GOOS=darwin GOARCH=arm64 go build -o epistemic-darwin-arm64
GOOS=windows GOARCH=amd64 go build -o epistemic-windows-amd64.exe
```

### Homebrew Formula (later)
```ruby
class Epistemic < Formula
  desc "Immutable contradiction tracking for rigorous reasoning"
  homepage "https://github.com/yourusername/epistemic"
  url "https://github.com/yourusername/epistemic/archive/v1.0.0.tar.gz"
  
  def install
    system "go", "build", "-o", bin/"epistemic"
  end
end
```

---

This roadmap gives you deterministic, explainable drift metrics while keeping the system lean and portable. No ML dependencies, just pure symbolic reasoning.




=======

Yes: moving the “pressure file” handling into Go makes it structurally reliable, for specific reasons that bash cannot match.

### What Go fixes, concretely

1. **Real YAML parsing**

* In bash you are doing line heuristics.
* In Go you unmarshal YAML into structs/maps, so indentation, ordering, whitespace, comments, quoting, and nesting stop mattering.

2. **Schema validation**

* You can enforce: required keys, types, ranges, and “either `confidence` or `pressure_index` must exist,” with explicit errors.
* In bash, missing fields become empty strings and downstream arithmetic quietly misbehaves.

3. **Canonical serialization**

* You can canonicalize the manifest before hashing (stable key order, exact formatting rules), so “entropy” is actually a content-addressed identity.
* Your current bash version accidentally omits tension from the hash (because it’s a comment), which is a correctness bug, not a style issue.

4. **Typed breach classification**

* You can make `type` an enum (or validate against typology registry) and produce consistent breach objects.
* Bash makes this a stringly-typed free-for-all.

### What “plug in with YAML better” should mean

Not “it parses more YAML.” It should mean:

* a strict struct for contradiction items, e.g.

```go
type Contradiction struct {
    Line          int      `yaml:"line"`
    Type          string   `yaml:"type"`
    Confidence    *float64 `yaml:"confidence,omitempty"`
    PressureIndex *float64 `yaml:"pressure_index,omitempty"`
    Description   string   `yaml:"description,omitempty"`
}
```

* a loader that:

  * unmarshals,
  * checks each item has `Type`,
  * computes an effective weight as `pressure_index ?? confidence ?? error`,
  * validates typology existence unless `--allow-unknown-types`,
  * returns a structured `PressureSummary` (count, mean weight, unknown types).

That makes your “pressure gate” deterministic and testable.

### One key warning

Go will not automatically give you “canonical YAML” for hashing unless you define canonicalization rules. YAML libraries can reorder keys and serialize floats differently. If hashing is central, you should hash a canonical format you control (e.g., sorted `key=value` lines, or canonical JSON), not whatever a YAML serializer happens to output.

Analytically: refactoring to Go will make the pressure pipeline reliable because it replaces brittle line-oriented heuristics with typed YAML unmarshalling, explicit schema validation, and deterministic canonicalization for hashing.
S