@echo off
REM OmniVoice Server Setup Script for Dungeon Card TTS
REM This script installs and starts the OmniVoice TTS server
REM Requires: Python 3.10+ and pip

echo === OmniVoice Server Setup ===
echo.

REM Check if Python is available
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is not installed or not in PATH.
    echo Install Python 3.10+ from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Check if omnivoice-server is installed
pip show omnivoice-server >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installing omnivoice-server via pip...
    pip install omnivoice-server
    if %ERRORLEVEL% neq 0 (
        echo.
        echo ERROR: Failed to install omnivoice-server.
        echo Try installing manually: pip install omnivoice-server
        pause
        exit /b 1
    )
)

echo Starting OmniVoice server on port 3900...
echo The game will connect to http://localhost:3900/v1/audio/speech
echo.
echo Press Ctrl+C to stop the server.
echo.
omnivoice-server --port 3900
pause
