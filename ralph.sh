#!/bin/bash
# Ralph Wiggum Loop - Iterative AI Agent Loop for Claude Code
# Based on Geoffrey Huntley's Ralph pattern & snarktank/ralph
#
# Usage: ./ralph.sh [max_iterations]
# Example: ./ralph.sh 20

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
PROMPT_FILE="$SCRIPT_DIR/PROMPT.md"
COMPLETION_SIGNAL="<promise>COMPLETE</promise>"
CANCEL_FILE="$SCRIPT_DIR/.ralph-cancel"
OUTPUT_FILE="$SCRIPT_DIR/.ralph-output"
CLAUDE_PID=""

# Clean up on exit
cleanup() {
  if [ -n "$CLAUDE_PID" ] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
    kill "$CLAUDE_PID" 2>/dev/null
    wait "$CLAUDE_PID" 2>/dev/null
  fi
  rm -f "$CANCEL_FILE" "$OUTPUT_FILE"
  echo ""
  echo "=== Ralph stopped ==="
  exit 0
}
trap cleanup SIGINT SIGTERM

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

# Clean up stale cancel file
rm -f "$CANCEL_FILE"

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
echo ""
echo "Stop with: Ctrl+C or './cancel.sh' from another terminal"
echo "========================="
echo ""

for ((i=1; i<=$MAX_ITERATIONS; i++)); do
  # Check for graceful cancellation
  if [ -f "$CANCEL_FILE" ]; then
    echo ""
    echo "=== Ralph cancelled gracefully (.ralph-cancel detected) ==="
    rm -f "$CANCEL_FILE" "$OUTPUT_FILE"
    exit 0
  fi

  # Refresh status
  DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
  TOTAL=$(jq '.userStories | length' "$PRD_FILE")

  echo ""
  echo "==============================================================="
  echo " Iteration $i / $MAX_ITERATIONS  |  Stories: $DONE/$TOTAL"
  echo "==============================================================="

  # Run Claude Code in background so Ctrl+C can kill it
  claude --dangerously-skip-permissions -p "$(cat $PROMPT_FILE)" --output-format text > "$OUTPUT_FILE" 2>&1 &
  CLAUDE_PID=$!

  # Wait for Claude to finish (this is interruptible by Ctrl+C)
  wait "$CLAUDE_PID" 2>/dev/null
  CLAUDE_PID=""

  # Read output
  OUTPUT=""
  if [ -f "$OUTPUT_FILE" ]; then
    OUTPUT=$(cat "$OUTPUT_FILE")
    echo "$OUTPUT"
  fi

  # Refresh status after iteration
  DONE=$(jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE")
  TOTAL=$(jq '.userStories | length' "$PRD_FILE")

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "$COMPLETION_SIGNAL"; then
    echo ""
    echo "=== ALL TASKS COMPLETE after $i iterations ($DONE/$TOTAL stories) ==="
    rm -f "$OUTPUT_FILE"
    exit 0
  fi

  echo ""
  echo "--- End of iteration $i  |  Stories: $DONE/$TOTAL done ---"
  sleep 2
done

echo ""
echo "=== Reached max iterations ($MAX_ITERATIONS) ==="
echo "Check progress.txt and prd.json for status."
rm -f "$OUTPUT_FILE"
exit 1
