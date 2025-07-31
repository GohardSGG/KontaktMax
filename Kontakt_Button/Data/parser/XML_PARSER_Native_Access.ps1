Remove-Item "$PSScriptRoot\NI_Backup\*.csv"
	[xml]$XML_File = Get-Content "C:\Program Files\Common Files\Native Instruments\Service Center\NativeAccess.xml"
	$XML_File.ProductHints.Product | % {
		If (-Not $_.Flavour) {
			$Name = $_.Name -replace "!","$"
			If (-Not $_.SNPID) {$SNPID = "ThirdParty"} Else {$SNPID = $_.SNPID.ToUpper()}
			If (-Not $_.Company) {$Company = "Not specified"} Else {$Company = $_.Company}
			If ($Name -eq "Audio Raiders - Sasha Soundlab") {$Name = "Sasha Soundlab"}
			If ( ($Name -eq "Cinestrings CORE") -or ($Name -eq "Cinestrings Core") -or ($Name -eq "CineStrings Core") ) {$Name = "CineStrings CORE"}
			If ( ($Name -eq "Cinebrass") -or ($Name -eq "Cinebrass CORE") -or ($Name -eq "Cinebrass Core") -or ($Name -eq "CineBrass Core") ) {$Name = "CineBrass CORE"}
			If ( ($Name -eq "Cinewinds PRO") -or ($Name -eq "Cinewinds Pro") -or ($Name -eq "CineWinds Pro") ) {$Name = "CineWinds PRO"}
			If ( ($Name -eq "Cineperc CORE") -or ($Name -eq "Cineperc Core") -or ($Name -eq "CinePerc Core") ) {$Name = "CinePerc CORE"}
			If ( ($Name -eq "Cineperc PRO") -or ($Name -eq "Cineperc Pro") -or ($Name -eq "CinePerc Pro") ) {$Name = "CinePerc PRO"}
			If ( ($Name -eq "Cineperc EPIC") -or ($Name -eq "Cineperc Epic") -or ($Name -eq "CinePerc Epic") ) {$Name = "CinePerc EPIC"}
			If ( ($Name -eq "Cineperc AUX") -or ($Name -eq "Cineperc Aux") -or ($Name -eq "CinePerc Aux") ) {$Name = "CinePerc AUX"}
			If ($Name -eq "Apollo Cinematic Guitars") {$Company = "Vir2"}
			If ($Name -eq "Damage") {$Company = "Heavyocity"}
			If ($Name -eq "The Finger") {$Company = "Tim Exile"}
			If ($Name -eq "Infinite Player") {$Name = "Studio ProFiles Infinite Player"}
			If ($Name -eq "ABSYNTH 5") {$Name = "Absynth 5"}
			If ($Name -eq "Rise And Hit") {$Name = "Rise and Hit"}
			If ($Name -eq "HardcoreBass") {$Name = "Hardcore Bass"}
			If ($Name -eq "HCB Vintage Expansion") {$Name = "Hardcore Bass XP"}
			If ($Name -eq "SOStrings") {$Name = "Symphonic Orchestra Volume 1 Strings"}
			If ($Name -eq "SOWoodwinds") {$Name = "Symphonic Orchestra Volume 2 Woodwinds"}
			If ($Name -eq "SOBrass") {$Name = "Symphonic Orchestra Volume 3 Brass"}
			If ($Name -eq "SOPercussion") {$Name = "Symphonic Orchestra Volume 4 Percussion"}
			If ($Name -eq "Boesendorfer290") {$Name = "Boesendorfer 290"}
			If ($Name -eq "MORPHOLOGY") {$Name = "Morphology"}
			If ($Name -eq "GALAXY STEINWAY 5.1") {$Name = "Galaxy Steinway 5.1"}
			If ( ($Name -eq "STORMDRUM") -or ($Name -eq "Stormdrum Kompakt") ) {$Name = "Storm Drum Kompakt"}
			If ($Name -eq "Stormdrum Intakt") {$Name = "Storm Drum Intakt"}
			If ($Name -eq "Sounds Of Polynesia") {$Name = "Sounds of Polynesia"}
			If ($Name -eq "PSP Percussive Adventures 2LE") {$Name = "PSP Percussive Adventures 2 LE"}
			If ($Name -eq "Percussive Adventures") {$Name = "Percussive Adventures 2"}
			If ($Name -eq "Altered States Intakt") {$Name = "Altered States"}
			If ($Name -eq "Ra") {$Name = "RA"}
			If ($Name -eq "Quantum Leap Symphonic Choirs") {$Name = "Symphonic Choirs"}
			If ($Name -eq "Ethno World Complete 3") {$Name = "Ethno World 3 Complete"}
			If ($Name -eq "Jazz and Bigband") {$Name = "Garritan Jazz"}
			If ( ($Name -eq "Vocal Force") -and ($SNPID -eq "768") ) {$Name = "Vocal Forge"}
			If ( ($Name -eq "EWQLSO Silver Ed") -or ($Name -eq "Silver Edition") ) {$Name = "EWQL Symphonic Orchestra Silver Edition"}
			If ( ($Name -eq "EWQLSO Gold Ed") -or ($Name -eq "Gold Edition") ) {$Name = "EWQL Symphonic Orchestra Gold Edition"}
			If ( ($Name -eq "EWQLSO Pro XP Strings") -or ($Name -eq "SOStrings PRO XP") ) {$Name = "EWQL Symphonic Orchestra Pro XP Strings"}
			If ( ($Name -eq "EWQLSO Pro XP Woodwinds") -or ($Name -eq "SOWoodwinds PRO XP") ) {$Name = "EWQL Symphonic Orchestra Pro XP Woodwinds"}
			If ( ($Name -eq "EWQLSO Pro XP Brass") -or ($Name -eq "SOBrass PRO XP") ) {$Name = "EWQL Symphonic Orchestra Pro XP Brass"}
			If ( ($Name -eq "EWQLSO Pro XP Percussion") -or ($Name -eq "SOPercussion PRO XP") ) {$Name = "EWQL Symphonic Orchestra Pro XP Percussion"}
			If ( ($Name -eq "EWQLSO Silver Ed PRO XP") -or ($Name -eq "EWQLSO Pro XP Silver") ) {$Name = "EWQL Symphonic Orchestra Pro XP Silver Edition"}
			If ( ($Name -eq "EWQLSO Gold Ed PRO XP") -or ($Name -eq "EWQLSO Pro XP Gold") ) {$Name = "EWQL Symphonic Orchestra Pro XP Gold Edition"}
			If ( ($Name -eq "SC Electric Guitar") -or ($Name -eq "Prominy SC Electric Guitar") ) {$Name = "Prominy SC"}
			If ( ($Name -eq "Presonus VI by SONiVOX") -or ($Name -eq "Presonus VI") ) {$Name = "Presonus Virtual Instrument"}
			If ( ($Name -eq "Chris Hein - Bass DE") -or ($Name -eq "Chris Hein Bass DE") ) {$Name = "Chris Hein Bass Download Edition"}
			If ( ($Name -eq "Chris Hein - Guitars DE") -or ($Name -eq "Chris Hein Guitars DE") ) {$Name = "Chris Hein Guitars Download Edition"}
			If ($Name -eq "Chris Hein Horns Solo DE") {$Name = "Chris Hein Horns Solo Download Edition"}
			If ($Name -eq "Chris Hein Horns Vol 2 DE") {$Name = "Chris Hein Horns Vol 2 Download Edition"}
			If ($Name -eq "Galaxy II DE") {$Name = "Galaxy II Download Edition"}
			If ($Name -eq "Galaxy 1929 German Baby Grand") {$Name = "Galaxy German Baby Grand"}
			If ($Name -eq "KOMPLETE 8 ULTIMATE") {$Name = "Komplete 8 Ultimate"}
			If ( ($Name -eq "Tony Newton Old School Bass") -or ($Name -eq "Tony's Old School Bass") -or ($Name -eq "Tonys Old School Bass") ) {$Name = "Tony Newton's Old School Bass"}
			If ( ($Name -eq "Tony Newton Bright and Funky Bass") -or ($Name -eq "Tony's Bright and Funky Bass") -or ($Name -eq "Tonys Bright and Funky Bass") ) {$Name = "Tony Newton's Bright and Funky Bass"}
			If ( ($Name -eq "Tony Newton Double Neck Bass") -or ($Name -eq "Tony's Double Neck Bass") -or ($Name -eq "Tonys Double Neck Bass") ) {$Name = "Tony Newton's Double Neck Bass"}
			If ( ($SNPID -eq "999") -and ( ($Name -eq "Komplete Selection") -or ($Name -eq "Komplete Selection, Percussion Hits") ) ) {$Name = "Komplete Selection - Percussion Hits"}
			If ($Name -eq "Mojo Horn Section") {$Name = "Mojo"}
			If ($Company -eq "Spitfire") {$Company = "Spitfire Audio"}
			If ($Name -eq "Albion III: Iceni") {$Name = "Iceni"}
			If ($Name -eq "BML Bones Vol.1") {$Name = "Spitfire BML Bones Vol.1"}
			If ( ($Name -eq "Solo Strings") -and ($Company -eq "Spitfire Audio") ) {$Name = "Spitfire Solo Strings"}
			If ( ($Name -eq "Orchestral Grand Piano") -and ($Company -eq "Spitfire Audio") ) {$Name = "Spitfire Orchestral Grand Piano"}
			If ( ($Name -eq "BML Horn Section") -or ($Name -eq "Spitfire BML201") -or ($Name -eq "Spitfire BML201 Horn Section") -or ($Name -eq "Spitfire BML201 Horn Section Vol 1") ) {$Name = "Spitfire BML201 Horn Section Vol.1"}
			If ( ($Name -eq "BML Low Brass") -or ($Name -eq "Spitfire BML203") -or ($Name -eq "Spitfire BML Low Brass") ) {$Name = "Spitfire BML203 Low Brass"}
			If ( ($Name -eq "BML Sable Strings Vol.1") -or ($Name -eq "BML301 Sable Strings") -or ($Name -eq "Spitfire BML301") -or ($Name -eq "Spitfire Sable vol.1") -or ($Name -eq "Sable Strings Vol.1") ) {$Name = "Spitfire BML301 Sable Strings Vol.1"}
			If ( ($Name -eq "BML Sable Strings Vol.2") -or ($Name -eq "BML302 Sable Strings") -or ($Name -eq "Spitfire BML302") -or ($Name -eq "Spitfire Sable vol.2") -or ($Name -eq "Sable Strings Vol.2") ) {$Name = "Spitfire BML301 Sable Strings Vol.2"}
			If ( ($Name -eq "BML Sable Strings Vol.3") -or ($Name -eq "BML303 Sable Strings") -or ($Name -eq "Spitfire BML303") -or ($Name -eq "Spitfire Sable vol.3") -or ($Name -eq "Sable Strings Vol.3") ) {$Name = "Spitfire BML301 Sable Strings Vol.3"}
			If ( ($Name -eq "BML Flute Consort") -or ($Name -eq "Spitfire BML101") -or ($Name -eq "Flute Consort Vol.1") -or ($Name -eq "Spitfire Flute Consort Vol.1") -or ($Name -eq "Spitfire BML101 Flute Consort") -or ($Name -eq "Spitfire BML101 Flute Consort Vol 1") ) {$Name = "Spitfire BML101 Flute Consort Vol.1"}
			If ( ($Name -eq "Harp REDUX") -or ($Name -eq "Harp Redux") ) {$Name = "Spitfire Harp REDUX"}
			If ($Name -eq "Harpsichord") {$Name = "Spitfire Harpsichord"}
			If ($Name -eq "Grand Cimbalom") {$Name = "Spitfire Grand Cimbalom"}
			If ( ($Company -eq "Output, Inc.") -or ($Company -eq "Output Inc.") -or ($Company -eq "Output Audio") ) {$Company = "Output"}
			If ( ($Company -eq "East West") -or ($Company -eq "Eastwest") -or ($Company -eq "EastWest") ) {$Company = "East West Quantum Leap"}
			If ( ($Name -eq "Phaedra") -or ($Company -eq "Zero") ) {$Company = "Zero-G"}
			If ($Name -eq "Acou6tics") {$Company = "Vir2"}
			If ( ($Company -eq "Sonic Couture") -or ($Company -eq "Soniccoutre") ) {$Company = "Soniccouture"}
			If ($Company -eq "Sonokinetic") {$Company = "Sonokinetic BV"}
			If ($Company -eq "SoundIron") {$Company = "Soundiron"}
			If (-Not $_.RegKey) {$RegKey = $_.Name} Else {$RegKey = $_.RegKey -replace "!","$"}
			If ($Name -eq "Guitar Rig 2") {$RegKey = "Guitar Rig 2"}
			If ($Name -eq "Shreddage 2") {$Name = "Shreddage II";$RegKey = "Shreddage II"}
			If ( ($Name -eq "Best Service - Chris Hein Horns Compact") -or ($RegKey -eq "Best Service - Chris Hein Horns Compact") ) {$Name = "Best Service - Chris Hein Horns Compact";$RegKey = "CHH Compact"}
			If ( ($Name -eq "Evolution Stratocaster") -or ($RegKey -eq "Evolution Stratocaster") ) {$Name = "Evolution Stratosphere";$RegKey = "Evolution Stratosphere"}
			If ( ($Name -eq "CineStrings - RUNS") -or ($RegKey -eq "CineStrings - RUNS") ) {$Name = "CineStrings RUNS";$RegKey = "CineStrings RUNS"}
			If ( ($Name -eq "Steven Slate Drum Platinum") -or ($RegKey -eq "Steven Slate Drum Platinum") ) {$Name = "Steven Slate Drums Platinum";$RegKey = "Steven Slate Drums Platinum"}
			If ( ($Name -eq "Complete Classical Collection") -and ($RegKey -eq "Classical Collection") ) {$Name = "Classical Collection"}
			If ( ($Name -eq "Hammersmith Pro") -or ($RegKey -eq "Hammersmith Pro") ) {$Name = "The Hammersmith Pro Edition";$RegKey = "The Hammersmith Pro Edition"}
			If ( ( ($Name -eq "Cinewinds") -or ($Name -eq "Cinewinds CORE") -or ($Name -eq "Cinewinds Core") -or ($Name -eq "CineWinds Core") ) -and ( ($Regkey -eq "Celtic Instruments") -or ($Company -eq "Big Fish Audio") ) ) {$Name = "Celtic Instruments"}
			If ( ($Name -eq "Cinewinds") -or ($Name -eq "Cinewinds CORE") -or ($Name -eq "Cinewinds Core") -or ($Name -eq "CineWinds Core") ) {$Name = "CineWinds CORE"}
			If ( ($Name -eq "Maschine 2") -and ($Regkey -eq "Maschine 2 Bundle") ) {$Name = "Maschine 2 Bundle"}
			If ( ($Name -eq "Pan Drums 2") -and ($Regkey -eq "Pan Drums 2") ) {$Name = "Pan Drums";$RegKey = "Pan Drums"}
			If ($Name -eq "World Percussion 2") {$Name = "World Percussion 2.0";$RegKey = "World Percussion 2.0"}
			If ( ($Name -eq "Quantum Damage") -and ($SNPID -eq "345") ) {$SNPID = "ThirdParty"}
			If ( ($Name -eq "Kontakt 6") -and ($SNPID -eq "667") ) {$Name = "KOMPLETE KONTROL A-SERIES Collection";$RegKey = "KOMPLETE KONTROL A-SERIES Collection"}
			If ( ($Name -eq "Adrenaline") -and ($SNPID -eq "735") ) {$Name = "PSP Adrenaline";$RegKey = "PSP Adrenaline"}
			If ( ($Name -eq "PSP AfroLatin Slam") -or ($Name -eq "AfroLatin Slam") ) {$Name = "PSP Afrolatin Slam";$RegKey = "PSP Afrolatin Slam"}
			If ( ($Name -eq "PSP Koncept+Funktion") -or ($Name -eq "Koncept+Funktion") -or ($Name -eq "PSP Koncept &amp; Funktion") ) {$Name = "PSP Koncept & Funktion";$RegKey = "PSP Koncept & Funktion"}
			If ( ($Name -eq "PSP NuJointz") -or ($Name -eq "NuJointz") -or ($Name -eq "Nu Jointz") ) {$Name = "PSP Nu Jointz";$RegKey = "PSP Nu Jointz"}
			If ( ($Name -eq "PSPVol7 The Operating Table") -or ($Name -eq "PSP The Operating Table") -or ($Name -eq "The Operating Table") ) {$Name = "PSPVol7 The Operating Table";$RegKey = "PSPVol7 The Operating Table"}
			If ( ($Name -eq "PSP Vapor Virtual Synthesizer") -or ($Name -eq "Vapor Virtual Synthesizer") ) {$Name = "PSP Vapor";$RegKey = "PSP Vapor"}
			If ( ( ($Name -eq "PSP Wired - The Elements of Trance") -or ($Name -eq "PSP Wired") ) -or ( ($Name -eq "Wired") -and ($SNPID -eq "728") ) ) {$Name = "PSP Wired - The Elements of Trance";$RegKey = "PSP Wired - The Elements of Trance"}
			If ($Name -eq "Ondes") {$Name = "Ondes Martenot";$RegKey = "Ondes Martenot"}
			If ($Name -eq "Largo") {$Name = "Largo";$RegKey = "SonokineticLargo"}
			$Object = [pscustomobject][ordered]@{
				"@SNPID"           = "$SNPID"
				"Library Name"     = "$Name"
				"Company"          = "$Company"
				"Registry Key"     = "$RegKey"
			}
			$Object | Export-Csv "$PSScriptRoot\NI_Backup\PS_Parsed_List.csv" -delimiter "`|" -NoTypeInformation -Append
		} Else {
			$XML_File.ProductHints.Product.Flavour | % {
				If ($_.Name) {
					If ($_.SNPID) {
						$SNPID = $_.SNPID.ToUpper()
						$Name = $_.Name -replace "!","$"
						If (-Not $_.RegKey) {$RegKey = $_.Name} Else {$RegKey = $_.RegKey -replace "!","$"}
						If ($Name -like "Guitar Rig 3*") {$RegKey = "Guitar Rig 3"}
						If ($Name -like "Guitar Rig 4*") {$RegKey = "Guitar Rig 4"}
						If ($Name -like "Guitar Rig 5*") {$RegKey = "Guitar Rig 5"}
						If ($Name -like "Reaktor 5*") {$RegKey = "Reaktor 5"}
						If ($Name -like "Reaktor 6*") {$RegKey = "Reaktor 6"}
						If ($Name -eq "Kontakt Player 4") {$RegKey = "Kontakt 4"}
						If ($Name -eq "Kontakt Player 5") {$RegKey = "Kontakt 5"}
						If ($Name -like "Kontakt 6*") {$RegKey = "Kontakt Application"}
						If ( ($Name -eq "Traktor Pro") -or ($Name -eq "Traktor Scratch Pro") -or ($Name -eq "Traktor Duo") -or ($Name -eq "Traktor Scratch Duo") -or ($Name -eq "Traktor LE") -or ($Name -eq "Traktor VMS Edition") -or ($Name -eq "Traktor Pioneer DDJ-T1 Edition") ) {$RegKey = "Traktor Pro"}
						If ( ( ($Name -eq "Traktor Scratch Pro 2") -or ($Name -eq "Traktor Pro 2") ) -and ($SNPID -eq "131139163") ) {$SNPID = "131139"}
						If ($Name -eq "Traktor Scratch Pro 2") {$Name = "Traktor Pro 2"}
						If ( ($Name -like "Traktor Pro 2*") -or ($Name -eq "Traktor Scratch Pro 2") -or ($Name -eq "Traktor Scratch Duo 2") -or ($Name -eq "Traktor Duo 2") -or ($Name -eq "Traktor LE 2") -or ($Name -eq "TRAKTOR Pioneer DDJ-T1 Edition 2") -or ($Name -eq "TRAKTOR Velocity Midi Station Edition 2") -or ($Name -eq "TRAKTOR Numark 4TRAK Edition 2") ) {$RegKey = "Traktor Pro 2"}
						If ($Name -like "Traktor Pro 3*") {$RegKey = "Traktor Pro 3"}
						If ($Name -like "Maschine 2*") {$RegKey = "Maschine 2"}
						$Company = "Native Instruments GmbH"
						$Object = [pscustomobject][ordered]@{
							"@SNPID"           = "$SNPID"
							"Library Name"     = "$Name"
							"Company"          = "$Company"
							"Registry Key"     = "$RegKey"
						}
						$Object | Export-Csv "$PSScriptRoot\NI_Backup\PS_Parsed_List.csv" -delimiter "`|" -NoTypeInformation -Append
}}}}}

$hs = new-object System.Collections.Generic.HashSet[string]
$reader = [System.IO.File]::OpenText("$PSScriptRoot\NI_Backup\PS_Parsed_List.csv")
try {
    while (($line = $reader.ReadLine()) -ne $null)
    {
        $t = $hs.Add($line)
    }
}
finally {
    $reader.Close()
}
$ls = new-object system.collections.generic.List[string] $hs;
$ls.Sort();
try
{
    $f = New-Object System.IO.StreamWriter "$PSScriptRoot\NI_Backup\PS_Parsed_List_quoted.csv" ;
    foreach ($s in $ls)
    {
        $f.WriteLine($s);
    }
}
finally
{
    $f.Close();
}

Get-Content "$PSScriptRoot\NI_Backup\PS_Parsed_List_quoted.csv" | ForEach-Object {$_.replace("""","").replace("@SNPID","SNPID")} | Set-Content "$PSScriptRoot\NI_Backup\Parsed_List.csv"

Remove-Item "C:\Users\$env:username\AppData\Local\Temp\lock.tmp", "$PSScriptRoot\NI_Backup\PS_Parsed_List.csv", "$PSScriptRoot\NI_Backup\PS_Parsed_List_quoted.csv"
