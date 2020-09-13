#!/bin/bash

set -x
set -e

# download Linux
mkdir -p $2
cd $2
curl -L https://$(curl -sL https://www.kernel.org | grep "Download complete tarball" | cut -d '.' -f 2- | cut -d '"' -f 1 | grep pub | head -n1) -o $1
