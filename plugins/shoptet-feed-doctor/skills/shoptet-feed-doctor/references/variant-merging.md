# Merging item variants


**Source:** Mergado Forum — topic „Sloučení variant" (variant merging) (category Nápověda / Pravidla; tags: heureka, pravidla, shoptet, varianty-produktů). Author: Leos_Humpolik, Apr 2024 (post edited 12×, last on April 20).

---

## How to merge item variants

This post covers:

- What the **Sloučení variant** (variant merging) rule is for
- How to recognize a so-called variant format
- Configuring the Sloučení variant rule
- The most common use case (Heureka → Shoptet)
- Frequently asked questions

## What the Sloučení variant rule is for

The rule converts multiple standalone products that form a group in the input feed — grouped (most often) by the ITEMGROUP_ID element — into a merged structure. The output is then a format such as Shoptet kompletní.

For example, in a Heureka feed, variants can be different sizes, colors, patterns, or product sets. Products belonging to the same group are marked in the feed by the ITEMGROUP_ID tag.

In such a feed, variants exist as standalone products sharing the same ITEMGROUP_ID value.

By contrast, other formats such as Shoptet or UpGates nest product variants inside a main item — the so-called Master product, which contains the variants.

The Sloučení variant rule converts between formats that keep variants standalone and formats that "group" them under a Master product.

---

*Graphical illustration of merging multiple variant products into "one product with variants":*


*(Diagram: left column „Heureka, Zbozi.cz, Google…" with three standalone boxes Položka A / Položka B / Položka C — red, green, and blue t-shirt; arrow to the right; right column „Shoptet, UpGates, …" with one box „Položka s variantami" containing varianta A / varianta B / varianta C.)*

## How to recognize a so-called variant format

***Sample feed with ITEMGROUP_ID:***
(Heureka feed, 3 color/size variants)
Each variant is a standalone item wrapped in a SHOPITEM element, grouped by ITEMGROUP_ID with the same value "34".


```xml
<SHOP>
  <SHOPITEM>
    <ITEM_ID>34_CER</ITEM_ID>
    <PRODUCTNAME>Columbia Squish N' Stuff Barva: Červená, Velikost: XL</PRODUCTNAME>
    <DESCRIPTION>Popis položky</DESCRIPTION>
    <URL>https://myshop.com/columbia-squish-n-stuff/?variantId=49</URL>
    <IMGURL>https://myshop.com/usr/34-1_columbia-squish-n--stuff.jpg</IMGURL>
    <PRICE_VAT>290,00</PRICE_VAT>
    <PARAM>
      <PARAM_NAME>Barva</PARAM_NAME>
      <VAL>Červená</VAL>
    </PARAM>
    <PARAM>
      <PARAM_NAME>Velikost</PARAM_NAME>
      <VAL>XL</VAL>
    </PARAM>
    <CATEGORYTEXT>Oblečení | Dětské oblečení</CATEGORYTEXT>
    <ITEMGROUP_ID>34</ITEMGROUP_ID>
  </SHOPITEM>
  <SHOPITEM>
    <ITEM_ID>34_ZEL</ITEM_ID>
    <PRODUCTNAME>Columbia Squish N' Stuff Barva: Zelená, Velikost: M</PRODUCTNAME>
    <DESCRIPTION>Popis položky</DESCRIPTION>
    <URL>https://myshop.com/columbia-squish-n-stuff/?variantId=55</URL>
    <IMGURL>https://myshop.com/usr/34-1_columbia-squish-n--stuff.jpg</IMGURL>
    <PRICE_VAT>290,00</PRICE_VAT>
    <PARAM>
      <PARAM_NAME>Barva</PARAM_NAME>
      <VAL>Zelená</VAL>
    </PARAM>
    <PARAM>
      <PARAM_NAME>Velikost</PARAM_NAME>
      <VAL>M</VAL>
    </PARAM>
    <CATEGORYTEXT>Oblečení | Dětské oblečení</CATEGORYTEXT>
    <ITEMGROUP_ID>34</ITEMGROUP_ID>
  </SHOPITEM>
  <SHOPITEM>
    <ITEM_ID>34_MOD</ITEM_ID>
    <PRODUCTNAME>Columbia Squish N' Stuff Barva: Modrá, Velikost: XL</PRODUCTNAME>
    <DESCRIPTION>Popis položky</DESCRIPTION>
    <URL>https://myshop.com/columbia-squish-n-stuff/?variantId=52</URL>
    <IMGURL>https://myshop.com/orig/34-2_columbia-squish-n--stuff.jpg</IMGURL>
    <PRICE_VAT>290,00</PRICE_VAT>
    <PARAM>
      <PARAM_NAME>Barva</PARAM_NAME>
      <VAL>Modrá</VAL>
    </PARAM>
    <PARAM>
      <PARAM_NAME>Velikost</PARAM_NAME>
      <VAL>XL</VAL>
    </PARAM>
    <CATEGORYTEXT>Oblečení | Dětské oblečení</CATEGORYTEXT>
    <ITEMGROUP_ID>34</ITEMGROUP_ID>
  </SHOPITEM>
</SHOP>
```

In a Shoptet feed, by contrast, the individual variants sit inside the Master product, wrapped in the VARIANT element.

***Sample feed with a Master product:***
(One item with 3 variants inside)


```xml
<SHOP>
  <SHOPITEM>
    <NAME>Columbia Squish N' Stuff</NAME>
    <ITEM_TYPE>product</ITEM_TYPE>
    <CATEGORIES>
      <CATEGORY>Oblečení > Dětské oblečení</CATEGORY>
    </CATEGORIES>
    <IMAGES>
      <IMAGE>https://myshoptet.com/34-1_columbia-squish-n--stuff.jpg</IMAGE>
      <IMAGE>https://myshoptet.com/34-2_columbia-squish-n--stuff.jpg</IMAGE>
    </IMAGES>
    <VARIANTS>
      <VARIANT>
        <CODE>34_CER</CODE>
        <PRICE>290</PRICE>
        <AVAILABILITY_IN_STOCK>Skladem</AVAILABILITY_IN_STOCK>
        <PARAMETERS>
          <PARAMETER>
            <NAME>Barva</NAME>
            <VALUE>Červená</VALUE>
          </PARAMETER>
          <PARAMETER>
            <NAME>Velikost</NAME>
            <VALUE>XL</VALUE>
          </PARAMETER>
        </PARAMETERS>
      </VARIANT>
      <VARIANT>
        <CODE>34_ZEL</CODE>
        <PRICE>290</PRICE>
        <AVAILABILITY_IN_STOCK>Skladem</AVAILABILITY_IN_STOCK>
        <PARAMETERS>
          <PARAMETER>
            <NAME>Barva</NAME>
            <VALUE>Zelená</VALUE>
          </PARAMETER>
          <PARAMETER>
            <NAME>Velikost</NAME>
            <VALUE>M</VALUE>
          </PARAMETER>
        </PARAMETERS>
      </VARIANT>
      <VARIANT>
        <CODE>34_MOD</CODE>
        <PRICE>290</PRICE>
        <AVAILABILITY_IN_STOCK>Skladem</AVAILABILITY_IN_STOCK>
        <PARAMETERS>
          <PARAMETER>
            <NAME>Barva</NAME>
            <VALUE>Modrá</VALUE>
          </PARAMETER>
          <PARAMETER>
            <NAME>Velikost</NAME>
            <VALUE>XL</VALUE>
          </PARAMETER>
        </PARAMETERS>
      </VARIANT>
    </VARIANTS>
  </SHOPITEM>
</SHOP>
```

Looking at the variant feed structure, note that **some elements are shared by all variants** (typically item name, categories, images, …) **and some elements sit at the variant level** (EAN, price, item code, …).

This is logical: an item's category placement in the e-shop is expected to be identical across variants. Price, EAN, availability, and item codes often differ, so those must live directly at the variant.

The **Sloučení variant rule lets you define exactly the behavior you want — i.e. the placement of each element within the feed**:

- Shared element
- Variant element placed directly at the variant

*Sample of shared elements at the Master product:*

```xml
<SHOP>
  <SHOPITEM>
    <!-- společné elementy (na ukázce zvýrazněny rámečkem): -->
    <NAME>Columbia Squish N' Stuff</NAME>
    <ITEM_TYPE>product</ITEM_TYPE>
    <CATEGORIES>
      <CATEGORY>Oblečení > Dětské oblečení</CATEGORY>
    </CATEGORIES>
    <IMAGES>
      <IMAGE>https://myshoptet.com/34-1_columbia-squish-n--stuff.jpg</IMAGE>
      <IMAGE>https://myshoptet.com/34-2_columbia-squish-n--stuff.jpg</IMAGE>
    </IMAGES>
    <VARIANTS>
      <VARIANT>
        <CODE>34_BIL</CODE>
        <PRICE>290</PRICE>
        <AVAILABILITY_IN_STOCK>Skladem</AVAILABILITY_IN_STOCK>
        <PARAMETERS>
          <PARAMETER>
            <NAME>Barva</NAME>
            <VALUE>Bílá</VALUE>
          </PARAMETER>
          <PARAMETER>
            <NAME>Velikost</NAME>
            <VALUE>XL</VALUE>
          </PARAMETER>
        </PARAMETERS>
      </VARIANT>
      <VARIANT>
        <CODE>34_BIL2</CODE>
        <PRICE>290</PRICE>
        <!-- zbytek ukázky na screenshotu oříznut … -->
```

> 📌 *The philosophy of the Sloučení variant rule:*
> *If an element is configured in the Sloučení variant rule, it is a "shared element". If an element is NOT configured in the merging rule, it is carried over to the item's variant.*

---

## How to configure the Sloučení variant rule:

*Sample rule configuration:*


*(Rule form on the screenshot:*
- *Rule name: `Sloučení variant položek`*
- *Rule type: `Sloučení variant`*
- *„Element pro výběr Master položky" (element for selecting the Master item): `ITEM_ID`*
- *„Element se sdružovacím kódem" (element holding the grouping code): `ITEMGROUP_ID`*
- *Table Element → Action type:*
  - *`NAME` → Kopírovat z master položky (copy from Master item)*
  - *`CATEGORIES | CATEGORY` → Kopírovat z master položky*
  - *`ITEM_TYPE` → Kopírovat z master položky*
  - *`IMAGES | IMAGE` → Sloučit hodnoty z variant (merge values from variants)*
  - *empty row: „zvolte element…" → „Zvolte typ akce")*

**1. „Element pro výběr Master položky"**
Defines the element used to find the appropriate "Master item" that all variants fall under.

> ► I want to know more about how Master item selection works
> *(collapsible section — content not expanded on the screenshot)*

**2. „Element se sdružovacím kódem"**
Specifies the element containing the ID used to group variants into one item. Most often this is ITEMGROUP_ID. The code in this element must be identical for all variants of one item.

**3. Element selection field**
Select the elements that should be shared by all variants of the item...

Then choose the action type — how values should be taken from the variants (i.e. from the originally standalone input products that form a group with the same ITEMGROUP_ID).

**4. Action type:**

- ***Kopírovat z Master položky*** (copy from Master item)
  The value is taken from the element on the Master item. By default, that is the item with the lowest ITEM_ID within the group of items sharing the same ITEMGROUP_ID.

- ***Sloučit hodnoty z variant*** (merge values from variants)
  Takes the element values from all items with the same ITEMGROUP_ID and merges them.

If the elements have identical values, they are merged into one. If the values differ, the element appears multiple times — see the IMAGE element in the sample above.

---

## How to prepare data correctly for Sloučení variant when targeting the Shoptet format

The following example shows how to use the *Sloučení variant* rule to prepare data for the Shoptet platform. The example assumes the input format is *Heureka produktový* with `ITEMGROUP_ID` set on the items.

### Configure the Sloučení variant rule correctly

The Sloučení variant rule now comes preconfigured so that on first launch it should already be set up ideally for the Shoptet format. Just verify the settings:

1. „Element pro výběr Master položky" is set to `ITEM_ID` or `CODE`.
2. „Element se sdružovacím kódem" is set to `ITEMGROUP_ID`.
3. Choose the appropriate parameters that should form the product variants (color, size, …)


*(On the screenshot: field „Parametry tvořící variantu produktu" (parameters forming the product variant) with values `Barva`, `Varianta`; field „Maximální počet parametrů, které tvoří variantu" (maximum number of parameters forming a variant) with value `2`; link ▼ Pokročilé nastavení (advanced settings).)*

This is the key part of the whole process. **The Sloučení variant rule then converts the copied parameters into the correct structure of the variant feed**.

> ⚠️ **Important note:**
> Into the variant-forming parameters, enter truly **all possible parameters** you know are used as product variants anywhere in your project.
>
> Different items may of course use different parameters. Enter every possible version into the field.
>
> Sample configuration:
>
> *(Field „Parametry tvořící variantu produktu" — example values: `Barva`, `Rozměry`, `Velikost`, `Délka`, `Typ`, `Průměr`.)*
>
> The system uses at most 1-3 parameters per item, according to this setting:
>
> *(Field „Maximální počet parametrů, které tvoří variantu" — example value: `2`.)*
>
> For each item, the *Sloučení variant* rule scans for matching parameters and, once found, uses them as the variants.

### Create an optimal name for variant products

Remember that after merging, the name of one of the variants becomes the shared name for all variants of the product. Be aware that names may contain the item's **size** and **color**, which is undesirable at this point.

Typical variant item names:

- *Tričko s krátkým rukávem Barva: Bílá, Velikost: M*
- *Tričko s krátkým rukávem Barva: Bílá, Velikost: XL*
- *Tričko s krátkým rukávem Barva: Červená, Velikost: S*
- *Tričko s krátkým rukávem Barva: Zelená, Velikost: XXL*
- …

**As you can see, such a name is undesirable**. In Mergado Editor, you can create a new *Proměnná* (variable) that **processes item names with a regular expression** to suit your needs.

*Sample variable configuration:*


*(Variable form on the screenshot:*
- *Input element: `NAME`*
- *Regular expression: `(.*?)(?=\s*Barva|\s*Velikost)(.*)`*
- *Test text: `Tričko s krátkým rukávem Barva: Bílá, Velikost: M`*

*Available variables (preview of the test text split: group 0 = full text, group 1 = „Tričko s krátkým rukávem", group 2 = „Barva: Bílá, Velikost: M"):*
- *Variable name no. 0 — `Tričko s krátkým rukávem Barva: Bílá, Velikost: M` — field empty*
- *Variable name no. 1 — `Tričko s krátkým rukávem` — field: `Nazev_bez_variant`*
- *Variable name no. 2 — `Barva: Bílá, Velikost: M` — field empty)*

**The configuration above does the following:**

1. Creates a new variable named Nazev_bez_variant
2. The new variable contains the original item name stripped of the size and color text

**The regular expression used:** `(.*?)(?=\s*Barva|\s*Velikost)(.*)`

Then simply write this variable into the NAME element of the variant items using the Přepsat (Rewrite) rule.

> ℹ️ *Adjust the regular expression as needed for the names of your chosen parameters.*

> ℹ️ *Ideally restrict the rule to a selection of items that have the ITEMGROUP_ID element set, so you don't accidentally modify items that are not meant to become variants.*

---

## Questions and answers:

*(clicking a heading reveals the answer — the answers are collapsed on the screenshots, so only the questions are listed below)*

- ► Why is the Sloučení variant rule not available in my rule selection at all?
- ► Why don't I see the merged products on the Products page even after enabling the "Sloučení variant" rule?
- ► What if I want to work with already-merged products on the Products page?
- ► On the Products page, how do I quickly tell which item the values shared by all variants will be taken from?
- ► How do I ensure an ideal Master item name?
- ► Can the Sloučení variant rule be used when I have a variant format not only on the output but also on the input?
- ► Why can't I change the application order of the Sloučení variant rule?
- ► What happens if an input item already has a variant structure?
- ► Why did developing the Sloučení variant rule take Mergado so long?

> ℹ️ **Want to try the Sloučení variant rule now?**
> Write to support@mergado.com, or register directly in our Výzkumná skupina (Research Group) and we will grant you early access to this new feature.

---


---

## Appendix: preparing spreadsheet data before merging

When the source data is not a feed but a spreadsheet (supplier export, Sheets), these techniques help before import/merging:

### Merging values under one ID (multiple images/variants on separate rows)

Joining 1–n values belonging to the same ID into one delimiter-separated string:

```
=TEXTJOIN(","; PRAVDA; KDYŽ($E$2:$E$100=E2; $G$2:$G$100; ""))
```

The resulting string is then split with the „Text do sloupců" (Text to columns) tool — Shoptet imports expect attributes like images as separate columns (Image1–ImageN).

### Assigning a grouping code based on matching names

When ITEMGROUP_ID is missing and variants can only be identified by an identical name — the formula assigns the same number to identical names and a number 1 higher to new names:

```
=KDYŽ(COUNTIF($C$2:C100; C2)=1; MAX($B$2:B100)+1; COUNTIF($C$2:C100; C2))
```

### Useful regular expressions for variables

- `\d+$` — number at end of text
- `\s{2}` — double space
- `P\d+$` — prefix "P" + number at end
- `Dotyková obrazovka:\s*([\d,.]+")` — capture a numeric value after a label
- `(.*?)(?=\s*Barva|\s*Velikost)(.*)` — strip variant info from the name (see above)
