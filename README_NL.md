# Emberveil — First Light · prototype 0.1

Een eerste speelbare basis voor Marc's top-down 2D idle / actieve RPG.
Emberveil is een tijdelijke werktitel. Gemaakt op 7 oktober 2026.

## Meteen spelen op Windows

1. Pak het volledige ZIP-bestand uit.
2. Open de map `Windows`.
3. Start `Emberveil.exe`. Er is geen Godot-installatie nodig om deze build te spelen.

Windows x86_64, toetsenbord en muis, grafische driver met OpenGL 3.3-ondersteuning.
Dit is een lokale, niet digitaal ondertekende ontwikkelbuild. Er is geen login,
installer of netwerkverbinding nodig. De applicatie verbindt niet met Steam.

## Je eerste avontuur

- Klik op **Begin exploring**.
- Loop naar een van de twee bomen ten zuidwesten van het dorpsplein.
- Druk **E** om automatisch herhaaldelijk hout te verzamelen. Bewegen of nogmaals
  E stopt de actie. Alleen gemarkeerde resource-bomen zijn hakbaar.
- Verzamel 5 hout. Volg de weg naar het noorden; bij de bergingang liggen ijzeraders.
- Verzamel 5 ijzererts. Ga terug naar de smid (de oven op het dorpsplein).
- Druk E en upgrade je zwaard. De grondstoffen worden verbruikt.
- Ga naar de mijnpoort in het noorden. E brengt je naar een aparte ondergrondse map.
- Volg de doorgangen naar het oosten om de Crystal Weaver te vinden.
- Val aan, let op de roze cirkels en ontwijk voordat ze ontploffen.
- De eerste overwinning geeft de **Weaver's Mantle**, een draagbare cosmetische
  mantel, plus kristallen. Dit is een lokaal game-item, geen Steam-inventoryitem.

De boss verschijnt na 60 seconden opnieuw zolang je in de mijn blijft. Bij opnieuw
binnengaan wordt de ontmoeting ook opnieuw opgebouwd. Herhaaloverwinningen geven
kristallen en combat-XP; de mantel ontgrendel je één keer.

## Besturing

| Toets | Actie |
|---|---|
| WASD / pijltjes | Lopen |
| E | Interactie / verzamelen starten of stoppen |
| Spatie | Zwaardaanval in je kijkrichting |
| Linkermuisknop in het speelveld | Richt en val aan naar de muis |
| Shift | Dodge met korte onkwetsbaarheid |
| Q | Potion gebruiken: maximaal 50 HP herstellen |
| I | Inventory en cosmetische mantel |
| M | Kaart van de huidige wereldlaag |
| H | Uitleg |
| Escape | Venster sluiten / pauzeren |
| F5 | Handmatig opslaan |

De knoppen onderaan bieden dezelfde acties. Gevechten pauzeren als een inventory-,
crafting-, kaart- of helpvenster openstaat. Arbeiders blijven werken.

## Idle, crafting en progressie

- Woodcutting, mining, fishing en combat hebben XP en levels.
- Herhaald verzamelen werkt zolang je bij de resource staat en het spel open is.
- Huur arbeiders bij het bord ten zuiden van het dorpsplein.
- Houthakker: 8 hout + 3 erts. Mijnwerker: 3 planken + 5 erts.
- Iedere ingehuurde arbeider produceert één resource per 12 seconden.
- Arbeiders blijven permanent in dienst, zonder doorlopende kosten in deze demo.
- Offline productie: maximaal 8 uur per afwezigheid, berekend bij opnieuw openen.
- Alleen arbeiders werken offline; eigen gathering en gevechten niet.
- Arbeiders geven geen combat-XP, mantel of andere actieve beloningen.
- Smid: 3 hout → 1 plank; 1 vis + 2 kruiden → 1 potion.
- Zwaard tier 2: 5 hout + 5 erts. Tier 3: 10 hout + 10 erts.
- Je geneest langzaam op het dorpsplein; het bosaltaar herstelt je volledig.
- Bij nederlaag kom je in het dorp terug zonder itemverlies.

## De wereld

Een vaste bovenwereld van 72 × 52 tegels met dorp, rivier en bruggen, kust,
velden, bergingang, betoverd bos, ruïnedecoratie en moeras. De ondergrondse map
heeft mijnkamers, smid, kristaladers en een bosskamer. Beide lagen hebben een kaart.

Dit is een functioneel prototype met eenvoudige, met code getekende visuals.
De eerder gemaakte conceptafbeeldingen zijn de artistieke richting, niet de
huidige kwaliteit van de speelbare graphics. Bomen zonder resource-markering
zijn decoratie; collision bestaat nu voor water, rotsmuren en dorpshuizen.

## Opslag

Autosave elke 15 seconden, na belangrijke aankopen/beloningen, bij afsluiten en
wanneer het venster focus verliest. De save wordt eerst naar een tijdelijk bestand
weggeschreven; de vorige save blijft als backup beschikbaar. Een beschadigde
hoofd-save probeert de backup te herstellen.

Windows-locatie:
`%APPDATA%\Godot\app_userdata\Emberveil — First Light\progress_v1.json`

Maak een kopie van die map voordat je saves handmatig verandert. Om opnieuw te
beginnen: sluit de game en verplaats de volledige save-map naar een backup-locatie.

Lokale tijd en saves zijn in deze offline demo aanpasbaar. Deze opslag mag later
niet als bewijs dienen voor verhandelbare Steam-drops. Een echte dropdienst hoort
spelacties en beloningen onafhankelijk te controleren.

## Project bewerken

Installeer Godot **4.5.1 standard** (geen .NET nodig), importeer
`Source/Emberveil/project.godot` en druk **F5** om het project te starten.
Alle gameplay staat in GDScript. Er zijn geen externe plugins of asset-downloads.

- `scripts/game.gd`: game loop, input, player, combat, interactions, rewards.
- `scripts/world.gd`: wereldlagen, tiles, objecten, collision en tekenfuncties.
- `scripts/progress.gd`: inventory, XP, idle workers en save/load.
- `scripts/hud.gd`: HUD, inventory, crafting, worker board, kaart en help.
- `main.tscn`: startscene.
- `export_presets.cfg`: Windows- en Linux-exportinstellingen.

Voor zelf exporteren: installeer via Godot de bijbehorende exporttemplates.
Kies Project > Export > Windows Desktop. Gebruik een outputmap buiten het project.

## Validatie

Getest met Godot 4.5.1 op Linux:

- Inladen en uitvoeren zonder GDScript compileerfouten.
- Gathering starten/stoppen, zwaardupgrade en kosten, arbeiders, layer travel.
- Aanvallen, bossbeloning, potion, ontwijk-onkwetsbaarheid en respawn.
- Save/load-roundtrip, beschadigde save → backup, offline cap en toekomstige klok.
- Bereikbaarheid van alle resource-/interactiepunten en de bosskamer.
- Echte rendercontrole van dorp, mijn, kaart, uitleg en craftingvenster.
- Windows x86_64 release-export voltooid. De EXE is hier niet op Windows uitgevoerd.

Zelf tests draaien (vervang `godot` door je Godot-programma):

```sh
godot --headless --path . -- --smoke
godot --headless --path . --script res://tests/routes_test.gd
```

`tests/progress_test.gd` schrijft en verwijdert test-saves; voer deze alleen uit met
aparte test-userdata. Bijvoorbeeld op Linux:

```sh
XDG_DATA_HOME=/tmp/emberveil-tests godot --headless --path . --script res://tests/progress_test.gd
```

## Nog te bouwen

Deze versie is geen complete Steam-release. Nog niet inbegrepen: multiplayer,
Steamworks/Inventory/Market, echte dropbeveiliging, controllerondersteuning,
geluid/muziek, definitieve sprites en animaties, uitgebreide quests, trading,
housing, guilds, volledige vestingdungeon en economie-balans voor langdurig spelen.

Logische volgende stap: eerst bewegen, de gathering-loop en het bossgevecht
beoordelen; daarna de gekozen pixelstijl uitwerken en uitbreiden per gebied.

## Licenties

De applicatie bevat Godot Engine 4.5.1. De MIT-licentie en notices van de
meegeleverde engine-componenten staan in `licenses/`. De projectvisuals zijn
rechtstreeks in GDScript getekend; geen externe game-assets zijn gekopieerd.
