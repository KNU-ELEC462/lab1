#!/bin/bash

TEST_DIR="$(dirname `realpath $0`)"
cd $TEST_DIR

REFERENCE_BINARY="./who3_ref"
TEST_BINARY="./who3"
SOURCE_FILES="who3.c utmplib.c"
REF_OUTPUT="ref_output.txt"
TEST_OUTPUT="test_output.txt"

# Cleanup function to remove temporary files
cleanup() {
    rm -f "$REF_OUTPUT" "$TEST_OUTPUT"
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

# Compile the test binary statically
gcc -static -o $TEST_BINARY $SOURCE_FILES 
if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed."
    exit 1
fi

# Check if reference and test binaries exist
if [ ! -f "$REFERENCE_BINARY" ]; then
    echo "ERROR: Reference binary ($REFERENCE_BINARY) not found."
    exit 1
fi

if [ ! -f "$TEST_BINARY" ]; then
    echo "ERROR: Test binary ($TEST_BINARY) not found after compilation."
    exit 1
fi

# Run both binaries and compare output
$REFERENCE_BINARY > "$REF_OUTPUT"
$TEST_BINARY > "$TEST_OUTPUT"

if ! diff -q "$REF_OUTPUT" "$TEST_OUTPUT" > /dev/null; then
    echo "FAILED: Output differs from the reference."
    exit 1
fi

# Check the number of 'read' system calls using strace
REF_READ_COUNT=$(strace -c $REFERENCE_BINARY 2>&1 | grep -w read | awk '{print $4}')
TEST_READ_COUNT=$(strace -c $TEST_BINARY 2>&1 | grep -w read | awk '{print $4}')

if [ "$REF_READ_COUNT" -ne "$TEST_READ_COUNT" ]; then
    echo "FAILED: read() system call count differs."
    exit 1
fi

echo "All tests passed!"
exit 0

