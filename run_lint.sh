#!/usr/bin/env bash

if hash luacheck 2>/dev/null; then
    # native lua check
    luacheck -q lualib service
else
    # docker
    docker run --rm -v $(pwd):/data yangm97/luacheck
fi
