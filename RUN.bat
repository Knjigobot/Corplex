@echo off
title Corplex Native OxCaml Engine
cd /d "%~dp0"
echo ======================================================
echo  CORPLEX NATIVE ENGINE (CORDIS & OXCAML)
echo  Spatiotemporal Complexity Analysis Platform
echo ======================================================
where dune >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [*] Building Corplex with Dune...
    dune build @all
    echo [*] Running Corplex Native CLI...
    dune exec bin/main.exe
) else (
    echo [*] Native OxCaml Dune build toolchain required.
    echo [*] Install via: opam install dune ocaml
)
pause
