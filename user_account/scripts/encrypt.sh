#!/bin/bash

# A suggested convention for output encrypted file suffix is: .enc.

file_in="${1}"
file_out="${2}"

openssl aes-256-cbc -a -salt -pbkdf2 -in "${file_in}" -out "${file_out}"
