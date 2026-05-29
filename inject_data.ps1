$body = '{ "email": "admin@collabsme.com", "password": "Admin1234" }'
$r = Invoke-WebRequest -Method Post -Uri "http://localhost:8000/api/auth/login/" -ContentType "application/json" -Body $body -UseBasicParsing
$token = ($r.Content | ConvertFrom-Json).tokens.access

# Add members to projects
$pids = @(9,10,11)
foreach ($p in $pids) {
  try { $m = Invoke-WebRequest -Method Post -Uri "http://localhost:8000/api/projects/$p/members/" -ContentType "application/json" -Headers @{ "Authorization" = "Bearer $token" } -Body '{ "user_id": 4, "role": "LEAD" }' -UseBasicParsing; Write-Host "P$p + user4: $($m.StatusCode)" } catch { Write-Host "P$p + user4: already" }
  try { $m2 = Invoke-WebRequest -Method Post -Uri "http://localhost:8000/api/projects/$p/members/" -ContentType "application/json" -Headers @{ "Authorization" = "Bearer $token" } -Body '{ "user_id": 18, "role": "MEMBER" }' -UseBasicParsing; Write-Host "P$p + user18: $($m2.StatusCode)" } catch { Write-Host "P$p + user18: already" }
}

$now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
$due = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")

$tasks = @(
  @{p=9; t="Maquette UI accueil"; s="DONE"; pr="HIGH"; a=4},
  @{p=9; t="Développement frontend"; s="IN_PROGRESS"; pr="HIGH"; a=4},
  @{p=9; t="Tests utilisateur"; s="TODO"; pr="MEDIUM"; a=18},
  @{p=10; t="Connexion Firebase"; s="DONE"; pr="HIGH"; a=4},
  @{p=10; t="Push notifications"; s="IN_PROGRESS"; pr="MEDIUM"; a=18},
  @{p=10; t="Déploiement iOS"; s="TODO"; pr="HIGH"; a=4},
  @{p=11; t="Conception API REST"; s="DONE"; pr="CRITICAL"; a=4},
  @{p=11; t="Documentation Swagger"; s="IN_PROGRESS"; pr="MEDIUM"; a=18},
  @{p=11; t="Tests d'intégration"; s="TODO"; pr="HIGH"; a=18}
)
foreach ($tk in $tasks) {
  $b = "{`"project`":$($tk.p),`"title`":`"$($tk.t)`",`"description`":`"Tâche $($tk.s)`",`"status`":`"$($tk.s)`",`"priority`":`"$($tk.pr)`",`"assigned_to`":$($tk.a),`"created_at`":`"$now`",`"due_date`":`"$due`"}"
  try {
    $rt = Invoke-WebRequest -Method Post -Uri "http://localhost:8000/api/projects/$($tk.p)/tasks/" -ContentType "application/json" -Headers @{ "Authorization" = "Bearer $token" } -Body $b -UseBasicParsing
    Write-Host "$($tk.t): $($rt.StatusCode)"
  } catch {
    $err = $_.Exception.Response
    $stream = $err.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    Write-Host "$($tk.t): FAILED - $($reader.ReadToEnd())"
  }
}

Write-Host "`n=== Injection terminée ==="
