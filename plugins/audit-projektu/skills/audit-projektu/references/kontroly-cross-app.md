# Kontroly napříč nástroji a kanály

Tady je hodnota, kterou žádný jednotlivý nástroj nedá. Zároveň je to sekce nejcitlivější na dostupnost: **u každé kontroly je uvedeno, co musí být k dispozici.** Když podmínka není splněná, kontrola se přeskočí a zapíše do reportu jako nezkontrolovaná s uvedením chybějící oblasti. Nikdy ji nenahrazuj dohadem z jedné strany.

Spouštěj až po dokončení jednotlivých oblastí, protože potřebuješ jejich nálezy.

### X1 Cena se rozchází mezi kanály
**Z1.** Vyžaduje: aspoň dva Mergado projekty téhož eshopu, volitelně Pricing Fox.
Detekce: pro vzorek produktů podle ID porovnej výslednou cenu ve všech projektech eshopu a proti ceně z Pricing Foxu. Rozdíl znamená, že v jednom kanálu jede jiná cenotvorba, než si někdo myslí. Google to navíc trestá jako rozpor s cenou na webu.
Uveď, který projekt se od ostatních odchyluje a o kolik.

### X2 Produkt skrytý v jednom kanálu a proplácený v jiném
**Z1.** Vyžaduje: aspoň dva projekty eshopu, případně Bidding Fox.
Detekce: produkty skryté nebo chybějící v jednom projektu a zároveň aktivně inzerované v jiném. Nejostřejší varianta je BF1 (bidding na produkt, který v exportu není).

### X3 Cenotvorba proti biddingu
**Z1.** Vyžaduje: Pricing Fox a Bidding Fox.
Detekce: produkty, u kterých PF snížil cenu nebo marži, zatímco BF drží CPC nastavené podle původní marže. Výsledkem je záporná jednotková ekonomika. Uveď produkty, jejich marži po přecenění a CPC.

### X4 Nekonzistentní názvy a data téhož produktu mezi projekty
**Z2.** Vyžaduje: aspoň dva projekty eshopu.
Detekce: vzorek ID produktů, porovnej název, značku a kategorii ve všech projektech. Rozdíly, které nejsou vysvětlené požadavky kanálu, jsou nález. Zákazník vidí u jednoho eshopu dvě různé identity produktu.

### X5 Nekonzistentní konvence konfigurace mezi projekty
**Z3.** Vyžaduje: aspoň dva projekty eshopu.
Detekce: porovnej pojmenování a strukturu pravidel a výběrů mezi projekty. Když jeden projekt má číslovanou strukturu a druhý "nové pravidlo (2)", údržba se dřív nebo později rozjede.

### X6 Pravidlo existuje v jednom kanálu a chybí v druhém
**Z2.** Vyžaduje: aspoň dva projekty eshopu.
Detekce: sada pravidel řešící stejnou věc (čištění názvů, doplnění značky, skrývání nedostupných) v jednom projektu je a v druhém ne. Uveď, co konkrétně druhému kanálu chybí. Tohle bývá důvod, proč jeden kanál "nefunguje" a nikdo neví proč.

### X7 Regrese proti minulému auditu
**Z2.** Vyžaduje: existující report z předchozího auditu, který uživatel dodá.
Detekce: porovnej nálezy. Rozděl na vyřešené, přetrvávající a nové. Nový nález v oblasti, která byla dřív čistá, je regrese a zaslouží zvláštní zmínku.
Bez předchozího reportu kontrolu přeskoč, ale do reportu napiš, že se tenhle audit dá použít jako základ pro příští srovnání.

### X8 Rozpor mezi obrázkem a feedem
**Z1.** Vyžaduje: Feed Image Editor a Mergado.
Detekce: sleva nebo cena vypálená v šabloně (FIE6) proti reálné ceně a slevě produktů z jejího výběru. Obrázek slibující minus 50 % u produktu bez slevy je problém pro klienta i pro platformu.

### X9 Osiřelé objekty napříč nástroji
**Z3.** Vyžaduje: Mergado a aspoň jedno rozšíření.
Detekce: Mergado výběry nepoužité nikde (pravidla, FIE šablony, BF strategie, PF pravidla), a naopak odkazy z rozšíření na výběry, které v Mergadu už nejsou (FIE2). Když některé rozšíření chybí, formuluj nález jako "nepoužito v dostupných oblastech", ne jako osiřelé.

### X10 Nákupní cena v cenotvorbě je vyrobená pravidlem z prodejní ceny
**Z1.** Vyžaduje: Pricing Fox a Mergado.
Detekce: vezmi `purchase_price_element` z `get_project_settings` Pricing Foxu a najdi ten element v mapě zápisů z fáze 1b. Když do něj zapisuje pravidlo, které počítá z prodejní ceny (typicky `calc` s výrazem `%CENA% * koeficient`), nákupní cena není náklad, ale odhad.
Potvrzující znak: `margin_min`, `margin_max` a `margin_avg` v metrikách pravidel jsou shodné a rovné doplňku koeficientu. U koeficientu 0,7 vyjde marže přesně 30 % u všech produktů, což se v reálném sortimentu nestává.
Proč to vadí: všechny marže, limity marže i hlášení „pod nákupní cenou" se pak počítají z čísla bez vztahu ke skutečným nákladům, takže cenová rozhodnutí jsou informovaná náhodou.
Doporučení: dokud není napojený skutečný ceník, nechat `purchase_price_element` prázdný. Prázdná hodnota je poctivější než vymyšlená, protože je z ní na první pohled vidět, že marže není známa.

Stejnou logikou zkontroluj i **konkurenční ceny**: import pojmenovaný „fake", „test" nebo „demo" se do Pricing Foxu nepropíše a v jeho rozhraní vypadají ceny a cenové pozice jako fakta. Když na nich stojí podmínky pravidel, patří to do reportu.
