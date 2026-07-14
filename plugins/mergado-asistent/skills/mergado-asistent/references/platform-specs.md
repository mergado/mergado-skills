# Platform specifications

Always link the current official specification (a live page), not a static copy. Verify the platform first (editing vs. conversion). For the Mergado-side format list, use `list_supported_feed_formats` and `get_format_specification`.

| Platform | Region | Official specification |
|---|---|---|
| Google Shopping / Merchant Center | global | https://support.google.com/merchants/answer/7052112 |
| Heureka.cz / .sk | CZ/SK | https://sluzby.heureka.cz/napoveda/xml-feed/ |
| Zboží.cz (Sklik) | CZ | https://napoveda.sklik.cz/reklamy/xml-feed/specifikace/ |
| GLAMI | CEE / fashion | https://help.glami.info/cs/xml-feed |
| Favi | CZ/CEE furniture | https://help.favionline.com/cs/vyznam-a-pozadavky-na-jednotlive-elementy |
| Biano | CZ/CEE furniture | no own spec — accepts Google/Heureka/Ceneo/Compari/Árukereső; CPC via `BIANO_CPC`. Info: https://www.mergado.com/integration/biano |
| Meta (Facebook + Instagram Shopping) | global | https://www.facebook.com/business/help/120325381656392 |
| TikTok Shop / Catalog | global | https://ads.tiktok.com/help/article/catalog-product-parameters |
| Pinterest | global | https://help.pinterest.com/en/business/article/data-source-ingestion |
| Microsoft Advertising / Bing Shopping | global | https://help.ads.microsoft.com/apex/index/3/en/51084 |
| Kelkoo | EU | https://developers.kelkoogroup.com/app/documentation/navigate/_merchant/merchantSystems/_/_OfferFeed/ProductDataSpecs |
| idealo | DE/EU | https://partner.idealo.com/ (CSV importer: https://idealo.github.io/csv-importer/en/csv/) |
| Ceneo.pl | PL | https://www.ceneo.pl/poradniki/Instrukcja-tworzenia-pliku-XML |
| Skroutz | GR | https://developer.skroutz.gr/products/xml_feed/ (validator: https://validator.skroutz.gr/) |
| Árukereső (Compari) | HU | https://www.arukereso.hu/static/feed-requirements.html |

## Notes
- **Meta** is also the source for **Instagram Shopping** (same catalog).
- **Pinterest, TikTok, Microsoft/Bing** largely follow the Google Product Data Specification — reuse a Google feed and check for platform-specific deviations.
- **Favi / Biano** have no public spec of their own — a Heureka-compatible feed works in most cases.
- **Category taxonomies for mapping:** Heureka category tree https://www.heureka.cz/direct/xml-export/shops/heureka-sekce.xml · Google product taxonomy with IDs — en-US https://www.google.com/basepages/producttype/taxonomy-with-ids.en-US.txt, cs-CZ https://www.google.com/basepages/producttype/taxonomy-with-ids.cs-CZ.txt (mapping recipe: `rules-cookbook.md`).
- Spec URLs change over time — treat this list as a starting point and confirm on the platform's own site.
