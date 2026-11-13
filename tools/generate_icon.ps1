Add-Type -AssemblyName System.Drawing
$projectRoot = Split-Path -Parent $PSScriptRoot
$image = [System.Drawing.Bitmap]::new(1024, 1024)
$g = [System.Drawing.Graphics]::FromImage($image)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.Clear([System.Drawing.ColorTranslator]::FromHtml('#1e694a'))
$cream = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#e7f2e7'))
$green = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#7eac70'))
$dark = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#176443'))
$white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$g.FillEllipse($cream, 95, 95, 834, 834)
$field = [System.Drawing.Point[]]@([System.Drawing.Point]::new(205,640),[System.Drawing.Point]::new(428,585),[System.Drawing.Point]::new(684,654),[System.Drawing.Point]::new(820,615),[System.Drawing.Point]::new(820,784),[System.Drawing.Point]::new(205,784))
$g.FillPolygon($green, $field)
$pen = [System.Drawing.Pen]::new($cream.Color, 20)
$g.DrawLines($pen, [System.Drawing.Point[]]@([System.Drawing.Point]::new(205,710),[System.Drawing.Point]::new(432,647),[System.Drawing.Point]::new(693,716),[System.Drawing.Point]::new(820,678)))
$g.DrawLine($pen, 420, 590, 420, 784)
$g.DrawLine($pen, 682, 655, 682, 784)
$pin = [System.Drawing.Point[]]@([System.Drawing.Point]::new(512,710),[System.Drawing.Point]::new(350,485),[System.Drawing.Point]::new(330,400),[System.Drawing.Point]::new(350,325),[System.Drawing.Point]::new(420,260),[System.Drawing.Point]::new(512,235),[System.Drawing.Point]::new(604,260),[System.Drawing.Point]::new(674,325),[System.Drawing.Point]::new(694,400),[System.Drawing.Point]::new(674,485))
$g.FillPolygon($dark, $pin)
$g.FillEllipse($white, 439, 318, 146, 146)
$g.FillEllipse($green, 468, 347, 88, 88)
$assetDir = Join-Path $projectRoot 'assets\icon'
New-Item -ItemType Directory -Path $assetDir -Force | Out-Null
$image.Save((Join-Path $assetDir 'app_icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
function Save-Icon([string]$path, [int]$pixels) {
  $output = [System.Drawing.Bitmap]::new($pixels, $pixels)
  $graphics = [System.Drawing.Graphics]::FromImage($output)
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.DrawImage($image, 0, 0, $pixels, $pixels)
  $output.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $output.Dispose()
}
@{'mipmap-mdpi'=48;'mipmap-hdpi'=72;'mipmap-xhdpi'=96;'mipmap-xxhdpi'=144;'mipmap-xxxhdpi'=192}.GetEnumerator() | ForEach-Object {
  Save-Icon (Join-Path $projectRoot ("android\app\src\main\res\{0}\ic_launcher.png" -f $_.Key)) $_.Value
}
$ios = Join-Path $projectRoot 'ios\Runner\Assets.xcassets\AppIcon.appiconset'
$contents = Get-Content -LiteralPath (Join-Path $ios 'Contents.json') -Raw | ConvertFrom-Json
foreach ($item in $contents.images) {
  $pixels = [int]([double](($item.size -split 'x')[0]) * [int]$item.scale.Substring(0,1))
  Save-Icon (Join-Path $ios $item.filename) $pixels
}
$g.Dispose(); $image.Dispose(); $cream.Dispose(); $green.Dispose(); $dark.Dispose(); $white.Dispose(); $pen.Dispose()
