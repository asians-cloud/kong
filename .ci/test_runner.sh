#!/bin/bash

set -e

if [ -z "$TESTS_TO_RUN_QUEUE_URL" ]
then
    echo "TESTS_TO_RUN_QUEUE_URL environment variable not set"
    exit 1
fi

if [ -z "$TESTS_FAILED_QUEUE_URL" ]
then
    echo "TESTS_FAILED_QUEUE_URL environment variable not set"
    exit 1
fi

# Function to run a test
run_test() {
    set $@
    local test_name=$1
    shift
    env $@ bin/busted -o gtest $test_name
    return $?
}

# Re-queue tests that failed in a previous run
while true
do
    message=$(aws sqs receive-message --queue-url "$TESTS_FAILED_QUEUE_URL" --max-number-of-messages 1)

    if [ -z "$message" ]
    then
        break
    fi

    ReceiptHandle=$(echo "$message" | jq -r '.Messages[0].ReceiptHandle')
    MessageBody=$(echo "$message" | jq -r '.Messages[0].Body')
    aws sqs send-message --queue-url "$TESTS_TO_RUN_QUEUE_URL" --message-body "$MessageBody"
    aws sqs delete-message --queue-url "$TESTS_FAILED_QUEUE_URL" --receipt-handle "$ReceiptHandle"
done

failures=0
# Process tests off the queue
while true
do
    message=$(aws sqs receive-message --queue-url "$TESTS_TO_RUN_QUEUE_URL" --max-number-of-messages 1)

    if [ -z "$message" ]
    then
        break
    fi

    ReceiptHandle=$(echo "$message" | jq -r '.Messages[0].ReceiptHandle')
    MessageBody=$(echo "$message" | jq -r '.Messages[0].Body')
    if ! run_test "$MessageBody"
    then
        aws sqs send-message --queue-url "$TESTS_FAILED_QUEUE_URL" --message-body "$MessageBody"
        failures=$(expr $failures + 1)
    fi
    aws sqs delete-message --queue-url "$TESTS_TO_RUN_QUEUE_URL" --receipt-handle "$ReceiptHandle"
done

if [ $failures != 0 ]
then
    echo "$failures test files failed"
    exit 1
fi

exit 0
