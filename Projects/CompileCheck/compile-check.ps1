<#
  ORMBr - verificação de compilação de Source/.

  Compila todas as units listadas em ORMBrCompileCheck.dpr com o compilador de
  linha de comando de uma versão do Delphi, para uma plataforma.

    Win32 / Win64 ............ compila e linka o programa ORMBrCompileCheck.
    Android64 / iOSDevice64 .. compila só até .dcu (sem link), para não exigir
                               SDK/NDK configurado.

  Toda a saída (.dcu, .exe, log) fica em Projects\CompileCheck\dcu\<versão>\<plataforma>.
  As pastas das dependências (DBCBr, DBEBr, CQLBr, JSONBr) são só lidas.

  Exemplo:
    .\compile-check.ps1 -Delphi 37.0 -Platform Win32 `
      -DepsRoots 'C:\deps\dbcbr\Source','C:\deps\dbebr\Source','C:\deps\cqlbr\Source','C:\deps\jsonbr\Source'

  Código de saída: 0 = sem erros; 1 = erro de compilação; 2 = erro de configuração.
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('23.0', '37.0')]
  [string] $Delphi,

  [Parameter(Mandatory = $true)]
  [ValidateSet('Win32', 'Win64', 'Android64', 'iOSDevice64')]
  [string] $Platform,

  [Parameter(Mandatory = $true)]
  [string[]] $DepsRoots,

  [string[]] $Defines = @()
)

$ErrorActionPreference = 'Stop'

$CheckDir   = $PSScriptRoot
$RepoRoot   = (Resolve-Path (Join-Path $CheckDir '..\..')).Path
$SourceDir  = Join-Path $RepoRoot 'Source'
$StudioDir  = "C:\Program Files (x86)\Embarcadero\Studio\$Delphi"
$OutDir     = Join-Path $CheckDir "dcu\$Delphi\$Platform"
$LogFile    = Join-Path $OutDir 'compile.log'

$Compilers = @{
  'Win32'       = 'dcc32.exe'
  'Win64'       = 'dcc64.exe'
  'Android64'   = 'dccaarm64.exe'
  'iOSDevice64' = 'dcciosarm64.exe'
}
$Compiler = Join-Path $StudioDir ("bin\" + $Compilers[$Platform])

if (-not (Test-Path $Compiler)) {
  Write-Host "Compilador não encontrado: $Compiler"
  exit 2
}
foreach ($LDepRoot in $DepsRoots) {
  if (-not (Test-Path $LDepRoot)) {
    Write-Host "Pasta de dependência não encontrada: $LDepRoot"
    exit 2
  }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Caminhos de busca: todas as pastas de Source/ (exceto Dependencies, que só tem
# readme) e todas as pastas das dependências informadas.
$SearchDirs = @($SourceDir)
$SearchDirs += Get-ChildItem $SourceDir -Recurse -Directory |
  Where-Object { $_.FullName -notmatch '\\Dependencies(\\|$)' } |
  ForEach-Object { $_.FullName }
foreach ($LDepRoot in $DepsRoots) {
  $SearchDirs += (Resolve-Path $LDepRoot).Path
  $SearchDirs += Get-ChildItem $LDepRoot -Recurse -Directory | ForEach-Object { $_.FullName }
}
$SearchPath = ($SearchDirs | Select-Object -Unique) -join ';'

if ($Platform -like 'Win*') {
  $Namespaces = 'System;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Winapi;System.Win'
} else {
  $Namespaces = 'System;Xml;Data;Datasnap;Web;Soap;FMX'
}

# Plataformas móveis: gera uma unit com a mesma lista de uses do .dpr e compila
# só essa unit, o que produz os .dcu sem passar pelo linker.
$DprFile = Join-Path $CheckDir 'ORMBrCompileCheck.dpr'
if ($Platform -like 'Win*') {
  $Target = $DprFile
} else {
  $DprText  = Get-Content $DprFile -Raw -Encoding UTF8
  $UsesText = [regex]::Match($DprText, '(?s)\buses\b(.*?);\s*begin').Groups[1].Value
  $Target   = Join-Path $OutDir 'ORMBrCompileCheckAll.pas'
  $UnitText = "unit ORMBrCompileCheckAll;`r`n`r`ninterface`r`n`r`nuses$UsesText;`r`n`r`nimplementation`r`n`r`nend.`r`n"
  Set-Content -Path $Target -Value $UnitText -Encoding UTF8
}

$DefineArg = @()
if ($Defines.Count -gt 0) {
  $DefineArg = @('-D' + ($Defines -join ';'))
}

# Response file: a linha de comando com todos os caminhos passa do limite do Windows.
$ResponseFile = Join-Path $OutDir 'compile.rsp'
$ResponseLines = @(
  '-B',
  '-Q',
  '-W+',
  "-NS$Namespaces",
  "-U`"$SearchPath`"",
  "-I`"$SearchPath`"",
  "-R`"$SearchPath`"",
  "-NU`"$OutDir`"",
  "-E`"$OutDir`""
) + $DefineArg
Set-Content -Path $ResponseFile -Value $ResponseLines -Encoding ASCII

Write-Host "Delphi $Delphi / $Platform -> $Target"
Push-Location $OutDir
try {
  & $Compiler "@$ResponseFile" $Target *> $LogFile
  $ExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}

$LogLines = Get-Content $LogFile

# Edições sem compilação por linha de comando (ex.: Community) saem com código 0
# e só escrevem esta mensagem; não conta como build verde.
if ($LogLines -match 'does not support command line compiling') {
  Write-Host 'Esta edição do Delphi não permite compilar por linha de comando.'
  Write-Host 'Compile ORMBrCompileCheck.dpr pela IDE (ver README.md desta pasta).'
  exit 2
}

$Errors   = @($LogLines | Where-Object { $_ -match '\b(Error|Fatal)\b' })
$Warnings = @($LogLines | Where-Object { $_ -match '\bWarning\b' })

Write-Host ("Erros: {0}  Avisos: {1}  Log: {2}" -f $Errors.Count, $Warnings.Count, $LogFile)
$Errors | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" }

if (($ExitCode -ne 0) -or ($Errors.Count -gt 0)) {
  exit 1
}
exit 0
