#!/usr/bin/env bash
rm -rf ~/Arquivos/.Trash*
onedrive --synchronize --single-directory '/mnt/arquivos/' --upload-only --no-remote-delete
