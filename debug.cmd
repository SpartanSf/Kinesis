@echo off
cd /d %~dp0
luajit.exe launch.lua %*
