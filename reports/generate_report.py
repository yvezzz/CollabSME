import json

report = {'django': {}, 'flutter': {}}

with open('reports/django_report.json') as f:
    r = json.load(f)
    report['django'] = {
        'summary': r['summary'],
        'created': r['created'],
        'duration': r['duration'],
    }

with open('reports/flutter_report.json') as f:
    lines = [l for l in f if l.startswith('{')]
    test_dones = [json.loads(l) for l in lines if '"type":"testDone"' in l]
    report['flutter'] = {
        'total': len([t for t in test_dones if not t.get('hidden')]),
        'passed': len([t for t in test_dones if t.get('result') == 'success' and not t.get('hidden')]),
        'failed': len([t for t in test_dones if t.get('result') != 'success' and not t.get('hidden')]),
    }

summary = f"Django: {report['django']['summary']['passed']}/{report['django']['summary']['total']} passed | Flutter: {report['flutter']['passed']}/{report['flutter']['total']} passed"
report['summary'] = summary
print(summary)

with open('reports/unified_report.json', 'w') as f:
    json.dump(report, f, indent=2)
