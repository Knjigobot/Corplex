@echo off
title Corplex Desktop (Cordis Complexity Analysis Runtime)
cd /d "%~dp0"
echo ======================================================
echo  CORPLEX DESKTOP PLATFORM (CORDIS RUNTIME)
echo  Spatiotemporal Complexity Analysis Engine in OxCaml
echo  Starting 24/7/365 Local Runtime...
echo ======================================================
if exist "gui\server.js" (
    node gui\server.js
) else if exist "server.js" (
    node server.js
) else (
    start "" "gui\index.html"
)
