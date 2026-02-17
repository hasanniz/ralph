#!/bin/bash
# Ralph Wiggum Loop - Iterative AI Agent Loop for Claude Code
# Based on Geoffrey Huntley's Ralph pattern & snarktank/ralph
#
# Usage: ./ralph.sh [max_iterations]
# Example: ./ralph.sh 20

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/PROMPT.md"
COMPLETION_SIGNAL="<promise>COMPLETE</promise>"

# Validate required files
if [ ! -f "$PROMPT_FILE" ]; then
  echo "Error: PROMPT.md not found."
  echo "Create a PROMPT.md with your task instructions first."
  exit 1
fi

if [ ! -f "$PRD_FILE" ]; then
  echo "Error: prd.json not found."
  echo "Create a prd.json with your user stories first."
  echo "See prd.json.example for the expected format."
  exit 1
fi

# Initialize progress file if missing
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Show current status
TOTAL=$(jq '.userStories | length' "$PRD_FILE")
DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")

echo "=== Ralph Wiggum Loop ==="
echo "Max iterations: $MAX_ITERATIONS"
echo "Stories: $DONE/$TOTAL complete"
echo "========================="
echo ""

for ((i=1; i<=$MAX_ITERATIONS; i++)); do
  # Refresh status
  DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
  TOTAL=$(jq '.userStories | length' "$PRD_FILE")

  echo ""
  echo "==============================================================="
  echo " Iteration $i / $MAX_ITERATIONS  |  Stories: $DONE/$TOTAL"
  echo "==============================================================="

  # Run Claude Code with fresh context each iteration
  OUTPUT=$(claude -p "$(cat $PROMPT_FILE)" --output-format text 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "$COMPLETION_SIGNAL"; then
    echo ""
    echo "=== ALL TASKS COMPLETE after $i iterations ==="
    exit 0
  fi

  echo ""
  echo "--- End of iteration $i ---"
  sleep 2
done

echo ""
echo "=== Reached max iterations ($MAX_ITERATIONS) ==="
echo "Check progress.txt and prd.json for status."
exit 1
