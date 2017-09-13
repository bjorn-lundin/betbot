#!/usr/bin/env bash

source betbot-data-manager.sh

main() {
    testListBuckets
    testListFiles
    #testSendEmail
    #syncDataLocalToS3 "bnl"
}

main "$@"
