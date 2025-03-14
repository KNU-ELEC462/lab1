#!/bin/bash

TEST_BINARY="./who3"
TEST_INPUT="./test_utmp"
SOURCE_FILES="who3.c utmplib.c"
REF_OUTPUT="who3_ref_output.txt"
TEST_OUTPUT="test_output.txt"

# Cleanup function to remove temporary files
cleanup() {
    rm -f "$TEST_OUTPUT"
}
# Ensure cleanup runs on exit (normal or error)
trap cleanup EXIT

# Check if source files exist
for file in $SOURCE_FILES; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Source file $file not found."
        exit 1
    fi
done

# Compile the test binary
gcc -o $TEST_BINARY $SOURCE_FILES 
if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed."
    exit 1
fi

# Check if test binaries exist
if [ ! -f "$TEST_BINARY" ]; then
    echo "ERROR: Test binary ($TEST_BINARY) not found after compilation."
    exit 1
fi

# Run test binary and compare output
$TEST_BINARY $TEST_INPUT > "$TEST_OUTPUT"

if ! diff -q "$REF_OUTPUT" "$TEST_OUTPUT" > /dev/null; then
    echo "FAILED: Output differs from the reference."
    exit 1
fi

# Check the number of 'read' system calls using strace
REF_READ_COUNT="5"
TEST_READ_COUNT=$(strace -c $TEST_BINARY $TEST_INPUT 2>&1 | grep -w read | awk '{print $4}')

if [ "$REF_READ_COUNT" -ne "$TEST_READ_COUNT" ]; then
    echo "FAILED: read() system call count differs."
    exit 1
fi

echo "All tests passed!"
exit 0

