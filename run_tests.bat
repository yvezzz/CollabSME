@echo off
echo Running Spring Boot tests...
cd /d "%~dp0backend"
call mvn test -q
echo.
if %errorlevel% equ 0 (
    echo Backend tests PASSED
) else (
    echo Backend tests FAILED
)
echo.
echo Running Flutter tests...
cd /d "%~dp0"
flutter test --machine > reports/flutter_report.json 2>&1
echo Flutter tests done. Report: reports/flutter_report.json
echo.
echo === Summary ===
echo Backend: see Maven output above
echo Flutter: see reports/flutter_report.json
pause
