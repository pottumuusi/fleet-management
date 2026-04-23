#!/bin/bash

file_in="${1}"
file_out="${2}"

openssl aes-256-cbc -d -a -pbkdf2 -in "${file_in}" -out "${file_out}"
