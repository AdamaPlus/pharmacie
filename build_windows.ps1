# =====================================================
# Script PowerShell - Build PharmaGuinée pour Windows
# Exécuter en tant qu'administrateur sur Windows
# =====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   BUILD PharmaGuinee - Windows Setup   " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ── Vérifier Flutter ─────────────────────────────────────────────
Write-Host "`n[1/4] Vérification de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter"
    Write-Host "✅ Flutter trouvé : $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter non trouvé !" -ForegroundColor Red
    Write-Host "👉 Téléchargez Flutter : https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    Write-Host "   puis relancez ce script." -ForegroundColor Yellow
    pause
    exit 1
}

# ── Installer les dépendances ─────────────────────────────────────
Write-Host "`n[2/4] Installation des dépendances..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors de flutter pub get" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "✅ Dépendances installées" -ForegroundColor Green

# ── Build Windows Release ─────────────────────────────────────────
Write-Host "`n[3/4] Compilation Windows Release..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur lors du build Windows" -ForegroundColor Red
    pause
    exit 1
}
Write-Host "✅ Build réussi !" -ForegroundColor Green

# ── Embarquer le runtime Microsoft Visual C++ ────────────────────
Write-Host "Téléchargement des composants Microsoft requis..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "installer_assets" | Out-Null
try {
    Invoke-WebRequest -Uri "https://aka.ms/vc14/vc_redist.x64.exe" `
                      -OutFile "installer_assets\vc_redist.x64.exe" `
                      -ErrorAction Stop
} catch {
    Write-Host "❌ Impossible de télécharger le composant Microsoft officiel." -ForegroundColor Red
    pause
    exit 1
}

# ── Créer l'installateur avec Inno Setup ─────────────────────────
Write-Host "`n[4/4] Création de l'installateur (.exe)..." -ForegroundColor Yellow

# Chercher Inno Setup
$iscc = Get-Command iscc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $iscc) {
    $innoSetupPaths = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "${env:ProgramFiles}\Inno Setup 6\ISCC.exe",
        "C:\ProgramData\chocolatey\bin\iscc.exe"
    )
    foreach ($path in $innoSetupPaths) {
        if (Test-Path $path) {
            $iscc = $path
            break
        }
    }
}

if ($iscc -eq $null) {
    Write-Host "⚠️  Inno Setup non trouvé." -ForegroundColor Yellow
    Write-Host "   Téléchargez-le sur : https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Alternative : le dossier build est prêt à la main :" -ForegroundColor Cyan
    Write-Host "   build\windows\x64\runner\Release\" -ForegroundColor White
    Write-Host ""
    Write-Host "   Créez un ZIP manuellement de ce dossier." -ForegroundColor Cyan

    # Créer un ZIP à la place
    Write-Host "`nCréation d'un ZIP portable..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path "output_setup" | Out-Null
    Compress-Archive -Path "build\windows\x64\runner\Release\*" `
                     -DestinationPath "output_setup\PharmaGuinee_Windows_v1.0.1_Portable.zip" `
                     -Force
    Write-Host "✅ Archive ZIP créée : output_setup\PharmaGuinee_Windows_v1.0.1_Portable.zip" -ForegroundColor Green
} else {
    Write-Host "✅ Inno Setup trouvé : $iscc" -ForegroundColor Green
    New-Item -ItemType Directory -Force -Path "output_setup" | Out-Null
    & $iscc "windows\pharmaguinee_installer.iss"

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✅ INSTALLATEUR CRÉÉ AVEC SUCCÈS !" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  📦 Fichier : output_setup\PharmaGuinee_Setup_v1.0.1.exe" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "❌ Erreur Inno Setup" -ForegroundColor Red
    }
}

Write-Host "`nAppuyez sur une touche pour terminer..." -ForegroundColor Gray
pause
