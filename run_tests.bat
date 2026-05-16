@echo off
echo Running Django tests...
cd /d "%~dp0backend"
py -m pytest --json-report --json-report-file=../reports/django_report.json -q
echo.
echo Django tests done. Report: reports/django_report.json
echo.
echo Running Flutter tests...
cd /d "%~dp0"
flutter test --machine > reports/flutter_report.json 2>&1
echo Flutter tests done. Report: reports/flutter_report.json
echo.
echo === Unified Summary ===
py -c "
import json
try:
    with open('reports/django_report.json') as f:
        r = json.load(f)
        s = r['summary']
        print(f'Django: {s[\"passed\"]} passed, {s[\"failed\"]} failed, {s[\"total\"]} total')
except: print('Django: no report')
try:
    with open('reports/flutter_report.json') as f:
        lines = [l for l in f if l.startswith('{') and '\"type\":\"testDone\"' in l]
        passed = sum(1 for l in lines if '\"result\":\"success\"' in l)
        failed = sum(1 for l in lines if '\"result\":\"failure\"' in l)
        print(f'Flutter: {passed} passed, {failed} failed')
except: print('Flutter: no report')
"
pause
