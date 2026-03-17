# PowerShell Mirror Folder

Jednoduchý PowerShell skript pro zrcadlení složek v reálném čase s podporou UNC cest a GUI výběrem.

## Funkce
- **Real-time monitoring**: Sleduje změny ve zdrojové složce a okamžitě je zrcadlí do cíle.
- **GUI Výběr**: Při prvním spuštění (nebo smazání konfigurace) vás vyzve k výběru složek.
- **UNC Podpora**: Funguje i se síťovými cestami (např. `\\NAS\Slozka`).
- **Průběh synchronizace**: Přímo v konzoli vidíte, které soubory se právě kopírují.
- **Automatický Admin**: Skript si sám vyžádá práva správce, pokud je nemá.
- **Robustní kódování**: Opraveno zobrazení českých znaků v konzoli.

## Jak začít
1. Stáhněte si `Mirror-Folder.ps1`.
2. Spusťte jej pomocí PowerShellu (Pravé tlačítko -> Run with PowerShell).
3. Vyberte zdrojovou a cílovou složku.
4. Skript poběží v pozadí (v okně konzole) a bude hlídat změny.

## Konfigurace
Nastavení se ukládá do souboru `mirror_config.json`. Pokud chcete změnit složky, stačí tento soubor smazat a spustit skript znovu.

## Důležité
> [!WARNING]
> Skript používá parametr `/MIR` (Mirror). To znamená, že soubory smazané ve zdroji budou smazány i v cíli!

## Vývoj
Skript používá `FileSystemWatcher` pro detekci událostí a `Robocopy` pro samotný přenos dat.
