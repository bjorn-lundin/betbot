#!/usr/bin/env bash

source betbot-aws.sh

main() {
    testListBuckets
    testListFiles
    #testSendEmail
    #syncDataLocalToS3 "bnl"
}

main "$@"
