$ErrorActionPreference = 'Continue'
$p = Join-Path (Get-Location) 'index.html'
$t = [System.IO.File]::ReadAllText($p)

Write-Output '== 1. extract JS =='
$start = $t.IndexOf('<script>') + 8
$end = $t.IndexOf('</script>')
$js = $t.Substring($start, $end - $start)
[System.IO.File]::WriteAllText((Join-Path $env:TEMP 'opencode\final-audit.js'), $js, [System.Text.UTF8Encoding]::new($false))
Write-Output 'extracted'

Write-Output '== 2. ID cross-reference =='
$refs = [regex]::Matches($js, "getElementById\('([^']+)'\)") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$missing = @()
foreach ($id in $refs) {
  $marker = 'id="' + $id + '"'
  if (-not $t.Contains($marker)) { $missing += $id }
}
if ($missing.Count -gt 0) { Write-Output ('MISSING: ' + ($missing -join ', ')) } else { Write-Output ('all ' + $refs.Count + ' referenced IDs exist') }

Write-Output '== 3. selector targets =='
foreach ($sel in @('.tilt','.reveal','.faq-item','data-count','data-tier','locked-form','book-grid','pay-box','file-drop','flash-timer','social-proof','slab1Proof','lockedNote')) {
  Write-Output ("  " + $sel + " : " + $t.Contains($sel))
}

Write-Output '== 4. HTML tag balance =='
$issues = @()
foreach ($tag in @('div','span','section','form','select','label','ul','li','a','button','svg','p','h1','h2','h3','style','script')) {
  $openPat = '<' + $tag + '>'
  $rx = [regex]::Escape('<' + $tag) + '(\s|>)'
  $o = ([regex]::Matches($t, $rx)).Count
  $c = ([regex]::Matches($t, '</' + $tag + '>')).Count
  if ($o -ne $c) { $issues += ($tag + ' open:' + $o + ' close:' + $c) }
}
if ($issues.Count -gt 0) { Write-Output ($issues -join ' | ') } else { Write-Output 'balanced' }

Write-Output '== 5. encoding =='
Write-Output ('  rupee count: ' + ([regex]::Matches($t, [string][char]8377)).Count)
Write-Output ('  em-dash: ' + $t.Contains([string][char]8212))
Write-Output ('  mojibake: ' + $t.Contains([string][char]226 + [string][char]128))

Write-Output '== 6. anchor targets =='
foreach ($a in @('#home','#about','#highlights','#schedule','#tickets','#book','#faq')) {
  $idOnly = $a.Substring(1)
  $marker = 'id="' + $idOnly + '"'
  Write-Output ('  ' + $a + ' : ' + $t.Contains($marker))
}

Write-Output '== 7. pricing chain =='
$rupee = [string][char]8377
Write-Output ('  slab1 live 399: ' + $t.Contains('> 399<'))
Write-Output ('  slab1 strike 499: ' + $t.Contains('was">' + $rupee + '499'))
Write-Output ('  slab2 live 499: ' + $t.Contains('> 499<'))
Write-Output ('  slab2 strike 599: ' + $t.Contains('was">' + $rupee + '599'))
Write-Output ('  JS PRICE_PER_PASS 399: ' + $js.Contains('PRICE_PER_PASS = 399'))
Write-Output ('  dropdown Slab1 399: ' + $t.Contains('Slab 1 ' + $rupee + '399'))

Write-Output '== 8. countdown epoch =='
Write-Output ('  page epoch: ' + $t.Contains('FLASH_OPEN_AT = 1789775340000'))
$d = Get-Date -Year 2026 -Month 9 -Day 19 -Hour 10 -Minute 49 -Second 0 -Millisecond 0
Write-Output ('  10:49 19Sep IST epoch: ' + ([long](($d.ToUniversalTime() - [DateTime]'1970-01-01T00:00:00Z').TotalSeconds * 1000)))

Write-Output '== 9. stray refs =='
$stray = @()
foreach ($bad in @('VIP Dhol Box','capMeter','closedBanner','paintLocked','paintCap','lastCap','pollMs','upi-qr.png','Mystery')) {
  if ($t.Contains($bad)) { $stray += $bad }
}
if ($stray.Count -gt 0) { Write-Output ('  FOUND: ' + ($stray -join ', ')) } else { Write-Output '  clean' }

Write-Output '== 10. form field hidden CSS =='
Write-Output ('  locked-form hide rule: ' + $t.Contains('.locked-form .book-grid'))
Write-Output ('  locked-form class on form: ' + $t.Contains('book-card reveal locked-form'))
