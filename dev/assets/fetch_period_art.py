#!/usr/bin/env python3

"""
Download the period pictures of the game and prepare them for Godot.

The pictures are scans of prints from the Adriatic around 1600, in the public
domain, from Wikimedia Commons (see DESIGN.md, "Art direction: period art"):
the town views and maps of Giovanni Francesco Camocio's "Isole famose, porti,
fortezze, e terre maritime" (Venice, 1574) and the costumes of Cesare
Vecellio's "Habiti antichi et moderni" (1590, in the edition of 1860).

For every picture, we:

1. download the original into .cache/period/ and check its SHA-256,
2. crop it (e.g., the figure of a costume plate, without the page of text),
3. tint it from black and white to ink on the paper of the game,
4. shrink it to at most PICTURE_SIZE pixels and save it as JPEG into
   assets/period/,
5. and record its provenance in assets/period/manifest.json.

Run it again after changing the list.
"""

import hashlib
import json
import pathlib
import sys
import time
import urllib.parse
import urllib.request
from typing import List, Optional, Tuple

from PIL import Image, ImageOps

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
CACHE_DIR = REPO_ROOT / ".cache" / "period"
PERIOD_DIR = REPO_ROOT / "assets" / "period"

# NOTE (mristin):
# Wikimedia asks automated clients to name themselves and a contact.
USER_AGENT = "BirdDogGame/0.1 (https://github.com/mristin/bird-dog)"

COMMONS = "https://commons.wikimedia.org/wiki/"
UPLOAD = "https://upload.wikimedia.org/wikipedia/commons/"

#: The longest side of a prepared picture, in pixels.
PICTURE_SIZE = 1600

#: The ink and the paper of the game (see scenes/menu/paper.gd).
INK = (51, 31, 15)
PAPER = (242, 227, 194)

CAMOCIO = "Giovanni Francesco Camocio, Isole famose, porti, fortezze, e terre maritime"
VECELLIO = "Cesare Vecellio, Habiti antichi et moderni (1590), edition of 1860"
ROSACCIO = "Giuseppe Rosaccio, Viaggio da Venetia a Costantinopoli (Venice, 1598)"
CORONELLI = "Vincenzo Coronelli, Isolario (Venice, 1688)"
PIRI_REIS = "Piri Reis, Kitab-ı Bahriye (a copy of the 17th century, Walters Art Museum)"

#: (the target, the Commons file, the path on upload.wikimedia.org, its SHA-256,
#: the crop as fractions (left, top, right, bottom) or None, the author and
#: the work, the year, and what the picture shows in the game)
PICTURES: List[
    Tuple[str, str, str, str, Optional[Tuple[float, float, float, float]], str, int, str]
] = [
    (
        "maps/adriatic.jpg",
        "Map of Italy and the eastern coast of the Adriatic Sea - Camocio Giovanni Francesco - 1574.jpg",
        "1/1b/Map_of_Italy_and_the_eastern_coast_of_the_Adriatic_Sea_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "1a9c5cc60fc30966a3b127192a011762f0acdf552c170a63095a3ec932ad8762",
        None,
        CAMOCIO,
        1574,
        "The whole Adriatic, for the decoration of the chart.",
    ),
    (
        "ports/pula.jpg",
        "Polla - Camocio Giovanni Francesco - 1574.jpg",
        "b/b2/Polla_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "1f409eabdbe29e18c909bc3bb13d5717238941d8f07ba3d1bb08a21ebae83b43",
        None,
        CAMOCIO,
        1574,
        "Pula with its Roman arena ('Coliseo antico').",
    ),
    (
        "ports/zadar.jpg",
        "Zarra et contado citta principale della Dalmatia - Camocio Giovanni Francesco - 1574.jpg",
        "5/57/Zarra_et_contado_citta_principale_della_Dalmatia_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "f962ba10480909b60171045efe5dc48b3f4d5e352eba0a74fe4fe64b84121b3a",
        None,
        CAMOCIO,
        1574,
        "Zadar and its countryside.",
    ),
    (
        "ports/sibenik.jpg",
        "Il fidelissimo Sebenicho et parte di Dalmatia - Camocio Giovanni Francesco - 1574.jpg",
        "c/ca/Il_fidelissimo_Sebenicho_et_parte_di_Dalmatia_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "9d13baaed68a634a49aaca862abef8cbbb0e94d66379579bc1b58f7d4b96d1c4",
        None,
        CAMOCIO,
        1574,
        "The town of Šibenik under its fortress.",
    ),
    (
        "ports/grebastica.jpg",
        "Sebenico - Camocio Giovanni Francesco - 1574.jpg",
        "8/8c/Sebenico_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "991b020992df18a2aa6d39440543c3420467ef1ed865f4af11d1fa75eca54c66",
        None,
        CAMOCIO,
        1574,
        "The coast around Šibenik, where Grebaštica lies.",
    ),
    (
        "people/baba_stana.jpg",
        "Dalmatina da Cherso - Vecellio Cesare - 1860.jpg",
        "7/7c/Dalmatina_da_Cherso_-_Vecellio_Cesare_-_1860.jpg",
        "5c38a7f9d78aebbf5b3a4b3a80d3f2291e9f408d7d8fbcb18d05e10c54113a0a",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Baba Stana: a Dalmatian woman of the island of Cres.",
    ),
    (
        "people/dalmatian_woman.jpg",
        "Donna Dalmatina o vero Schiavona - Vecellio Cesare - 1860.jpg",
        "7/7a/Donna_Dalmatina_o_vero_Schiavona_-_Vecellio_Cesare_-_1860.jpg",
        "b44a2436a57a91410da5da153ddeb623740091f50b88528724ea7883de092259",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A Dalmatian woman, a local in the ports.",
    ),
    (
        "people/girl.jpg",
        "Giovanetta Ragusea - Vecellio Cesare - 1860.jpg",
        "a/ab/Giovanetta_Ragusea_-_Vecellio_Cesare_-_1860.jpg",
        "d1a415a744c6ee40061ee6494e08d48609e898df0e9412aad699056014b87158",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A young girl of Ragusa, for the children of Grebaštica.",
    ),
    (
        "people/farmer.jpg",
        "Contadino al mercato di Venetia - Vecellio Cesare - 1860.jpg",
        "4/43/Contadino_al_mercato_di_Venetia_-_Vecellio_Cesare_-_1860.jpg",
        "8efcb6b443465b99f007ecd91ab53fcfec5e7d51805a81d4a47b603e734bbe83",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A man with a straw hat on his way to the market, a local in the ports.",
    ),
    (
        "people/porter.jpg",
        "Cestaruoli che attendono alle beccarie et alle pescarie - Vecellio Cesare - 1860.jpg",
        "8/85/Cestaruoli_che_attendono_alle_beccarie_et_alle_pescarie_-_Vecellio_Cesare_-_1860.jpg",
        "89bde3f257cdcf3f38277b01f14226e17dcc75118e422d1fb7946090d51a7050",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A porter of the fish market, a local in the ports.",
    ),
    (
        "ports/korcula.jpg",
        "Cruzola - Rosaccio Giuseppe - 1598.jpg",
        "8/87/Cruzola_-_Rosaccio_Giuseppe_-_1598.jpg",
        "2655a40f50fa1ffc7c7a22a0a889444d9de7224173001afb34049daa77947814",
        None,
        ROSACCIO,
        1598,
        "Korčula.",
    ),
    (
        "ports/hvar.jpg",
        "Liesna - Camocio Giovanni Francesco - 1574.jpg",
        "3/34/Liesna_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "07a157d504782ed6cd3f08aa57e26b3167b5b1b674977ff2deb571e87f517949",
        None,
        CAMOCIO,
        1574,
        "Hvar.",
    ),
    (
        "ports/split.jpg",
        "Spallato citta nobile et antiqua patria di Diocletiano - Camocio Giovanni Francesco - 1574.jpg",
        "b/b9/Spallato_citta_nobile_et_antiqua_patria_di_Diocletiano_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "e11277e983ea369496ae3c0d03b94042642f4655543e05b638268b234e90d955",
        None,
        CAMOCIO,
        1574,
        "Split with the palace of Diocletian.",
    ),
    (
        "ports/dubrovnik.jpg",
        "Ragusa - Rosaccio Giuseppe - 1598.jpg",
        "d/dd/Ragusa_-_Rosaccio_Giuseppe_-_1598.jpg",
        "d7e7a9a6604c58024040ec592b90f50d8a0854c41c07dc3097111019da0a0c59",
        None,
        ROSACCIO,
        1598,
        "Ragusa (Dubrovnik).",
    ),
    (
        "ports/kotor.jpg",
        "Cataro - Rosaccio Giuseppe - 1598.jpg",
        "7/78/Cataro_-_Rosaccio_Giuseppe_-_1598.jpg",
        "651dd72751ce9c7ad1e4daaa54a75eaae0da316ec740cabf52b02bf8e2e8add6",
        None,
        ROSACCIO,
        1598,
        "Kotor.",
    ),
    (
        "ports/herceg_novi.jpg",
        "Castel Novo - Camocio Giovanni Francesco - 1574.jpg",
        "c/cb/Castel_Novo_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "d0406783b1d629898b68833980df74fd41b126de5c2e860111553b6a615f3d31",
        None,
        CAMOCIO,
        1574,
        "Herceg Novi (Castel Novo).",
    ),
    (
        "ports/ulcinj.jpg",
        "Dulcigno - Camocio Giovanni Francesco - 1574.jpg",
        "0/03/Dulcigno_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "794923b5ddcb2d8b4920822d3a843979f2a35f4b37a358ac2caeddd2848b8036",
        None,
        CAMOCIO,
        1574,
        "Ulcinj (Dulcigno).",
    ),
    (
        "ports/durres.jpg",
        "Durazzo - Camocio Giovanni Francesco - 1574.jpg",
        "9/9c/Durazzo_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "b438fa18eca681af19488f9187f54049b53b9a342a3de190947ebd45b3f9e8e3",
        None,
        CAMOCIO,
        1574,
        "Durrës (Durazzo).",
    ),
    (
        "ports/vlore.jpg",
        "Valona - Camocio Giovanni Francesco - 1574.jpg",
        "c/ce/Valona_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "bafbe73476718aec81717a55694a477b875b9dcc9398ba79051013ea45d48f68",
        None,
        CAMOCIO,
        1574,
        "Vlorë (Valona) and its bay.",
    ),
    (
        "ports/corfu.jpg",
        "Corfu - Rosaccio Giuseppe - 1598.jpg",
        "0/01/Corfu_-_Rosaccio_Giuseppe_-_1598.jpg",
        "6d5fae66bcaecbb9c78e43f7384de6e96baa76afa372b830bea727e2e7fd2bf8",
        None,
        ROSACCIO,
        1598,
        "Corfu.",
    ),
    (
        "ports/parga.jpg",
        "Parga - Coronelli Vincenzo - 1688.jpg",
        "9/9f/Parga_-_Coronelli_Vincenzo_-_1688.jpg",
        "605bd590a781420871bec8f2e7097bee4aa90700a13e9bddef4e07d4a15a1578",
        None,
        CORONELLI,
        1688,
        "Parga.",
    ),
    (
        "ports/preveza.jpg",
        "Colfo della Prevesa - Camocio Giovanni Francesco - 1574.jpg",
        "0/02/Colfo_della_Prevesa_-_Camocio_Giovanni_Francesco_-_1574.jpg",
        "1ceb618dcae4969a15e2fe4241510ef46c97f24373841208542e861c69e6f25a",
        None,
        CAMOCIO,
        1574,
        "The gulf of Preveza.",
    ),
    (
        "ports/venice.jpg",
        "Venetia - Jacomo Franco fecit - btv1b550052418.jpg",
        "f/fc/Venetia_-_Jacomo_Franco_fecit_-_btv1b550052418.jpg",
        "9eddc786762e9a565f878c0afd8a77efd742dae982f79f585465157b89cc7aec",
        None,
        "Giacomo Franco, Venetia (Venice, about 1597)",
        1597,
        "Venice from above, with its ships.",
    ),
    (
        "ports/trieste.jpg",
        "Golfo de Trieste - Rosaccio Giuseppe - 1598.jpg",
        "d/dd/Golfo_de_Trieste_-_Rosaccio_Giuseppe_-_1598.jpg",
        "8d046d912a91f06816b84611ae8756fd1655fc5eb8e325900efc44f859eb2fda",
        None,
        ROSACCIO,
        1598,
        "The gulf of Trieste.",
    ),
    (
        "ports/senj.jpg",
        "Segna - btv1b53194564t (2 of 3).jpg",
        "8/81/Segna_-_btv1b53194564t_%282_of_3%29.jpg",
        "04ee2012ef8a9f64e3cd18e8e6acd12116cff5e0e3fa3d4af44f1833dd850053",
        None,
        "Francesco Valegio, Segna (Venice, 1616)",
        1616,
        "Senj, the town of the uskoks.",
    ),
    (
        "ports/pag.jpg",
        "Isola di Pago - Rosaccio Giuseppe - 1598.jpg",
        "9/90/Isola_di_Pago_-_Rosaccio_Giuseppe_-_1598.jpg",
        "85e131d768a424f2391508f6fe11f2b137073db8ae6e7c525d50fbe3f164be25",
        None,
        ROSACCIO,
        1598,
        "The island of Pag.",
    ),
    (
        "ports/rijeka.jpg",
        "S. Veit am Flaum (BM 1898,0725.8.1626).jpg",
        "0/09/S._Veit_am_Flaum_%28BM_1898%2C0725.8.1626%29.jpg",
        "d142acb0567349a848fb03b2903c4a68d425406d3a32432c1fd60ea2f75a0ce0",
        None,
        "Matthäus Merian, S. Veit am Flaum (1649)",
        1649,
        "Rijeka.",
    ),
    (
        "ports/ancona.jpg",
        "Braun Ancona UBHD.jpg",
        "d/d7/Braun_Ancona_UBHD.jpg",
        "67dbea8eaf141c1a641f195d9f7b86179ede1e3dd1f946d30c849a6b3fcb60fd",
        None,
        "Georg Braun and Frans Hogenberg, Civitates Orbis Terrarum (1572)",
        1572,
        "Ancona.",
    ),
    (
        "ports/bari.jpg",
        "Piri Reis - Map of the Town of Bari and the Surrounding Area - Walters W658203A - Full Page.jpg",
        "e/e5/Piri_Reis_-_Map_of_the_Town_of_Bari_and_the_Surrounding_Area_-_Walters_W658203A_-_Full_Page.jpg",
        "b36864fc5d1260954a0a99b9647baf53512a34d8f7524490b0935dc3b85e2809",
        None,
        PIRI_REIS,
        1650,
        "Bari.",
    ),
    (
        "ports/brindisi.jpg",
        "Piri Reis - Map of the Port of Brindisi - Walters W658205A - Full Page.jpg",
        "0/08/Piri_Reis_-_Map_of_the_Port_of_Brindisi_-_Walters_W658205A_-_Full_Page.jpg",
        "9016621a5b1c1f60b0d18ae6788122ce0b4c9fef3c1cbbe1d75dded8b4af1504",
        None,
        PIRI_REIS,
        1650,
        "The port of Brindisi.",
    ),
    (
        "ports/otranto.jpg",
        "Otranto by Piri Reis.jpg",
        "a/a2/Otranto_by_Piri_Reis.jpg",
        "8b584c42264fafb6f0a722d081f4dff0f58b560b29e2f6f48ace35dbb9abdccf",
        None,
        PIRI_REIS,
        1650,
        "Otranto.",
    ),
    (
        "ports/rovinj.jpg",
        "Piri Reis - Map of the Coastline from Pula to Rovinj - Walters W658172B - Full Page.jpg",
        "8/82/Piri_Reis_-_Map_of_the_Coastline_from_Pula_to_Rovinj_-_Walters_W658172B_-_Full_Page.jpg",
        "3a98ab20db7ce8fe4c0dc83c43f98bce4083ae96b2187a5266dc8edd2ec04d59",
        (0.1, 0.06, 0.85, 0.42),
        PIRI_REIS,
        1650,
        "Rovinj, walled on its peninsula.",
    ),
    (
        "people/shipwright.jpg",
        "Habito della maestranza dell'arsenale - Vecellio Cesare - 1860.jpg",
        "4/4e/Habito_della_maestranza_dell%27arsenale_-_Vecellio_Cesare_-_1860.jpg",
        "2500fc148c012d2f0a22ea75d64b5dc54691757be98938332fdfc7d107550c24",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Master Ivan: a craftsman of the Arsenal of Venice.",
    ),
    (
        "people/doctor.jpg",
        "Dottori di legge et medici, per tutta la Lombardia - Vecellio Cesare - 1860.jpg",
        "3/38/Dottori_di_legge_et_medici%2C_per_tutta_la_Lombardia_-_Vecellio_Cesare_-_1860.jpg",
        "ea311aa1fb8289dc82717304f5cca7036e5d71ea3c37e086fa02487943846407",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Doctor Marin: a doctor in his robe.",
    ),
    (
        "people/young_man.jpg",
        "Habito de' giovanetti venetiani et d'altri luoghi d'Italia - Vecellio Cesare - 1860.jpg",
        "0/06/Habito_de%27_giovanetti_venetiani_et_d%27altri_luoghi_d%27Italia_-_Vecellio_Cesare_-_1860.jpg",
        "00a96d23590239c6c9774d256449660838e721d1097b837d97dc57dba74d6429",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A young man.",
    ),
    (
        "people/uskok.jpg",
        "Capo di Uscocchi - Vecellio Cesare - 1860.jpg",
        "1/15/Capo_di_Uscocchi_-_Vecellio_Cesare_-_1860.jpg",
        "1d702f766c13b8f80d6774af96d99dd4ec295b2ed26608e5f18016a37b50537a",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Juraj: a captain of the uskoks.",
    ),
    (
        "people/kadi.jpg",
        "Cadil eschier - Vecellio Cesare - 1860.jpg",
        "8/88/Cadil_eschier_-_Vecellio_Cesare_-_1860.jpg",
        "08e22454991b9f502e1384cad90cffd09d882e40db9483e6c60085e4d5bd56e9",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "The kadı: an Ottoman judge.",
    ),
    (
        "people/corsair.jpg",
        "Habito di Turco pirato - Vecellio Cesare - 1860.jpg",
        "6/69/Habito_di_Turco_pirato_-_Vecellio_Cesare_-_1860.jpg",
        "1c97905a1c8dcfd9875ce645ffcea03568682fbb6de1f6b7e1f0667960ceabe5",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Crooked Mast: a corsair captain.",
    ),
    (
        "people/scribe.jpg",
        "Vicario, o dottore, o assessore in Terra Ferma dello Stato Veneto - Vecellio Cesare - 1860.jpg",
        "6/6a/Vicario%2C_o_dottore%2C_o_assessore_in_Terra_Ferma_dello_Stato_Veneto_-_Vecellio_Cesare_-_1860.jpg",
        "3c72fffeb65707300832e9e145b6d99de70e96b7f39402c7660bf38aea83ea15",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "The Aga's scribe: a man of the pen.",
    ),
    (
        "people/merchant.jpg",
        "Mercanti et bottegai di Venetia - Vecellio Cesare - 1860.jpg",
        "e/eb/Mercanti_et_bottegai_di_Venetia_-_Vecellio_Cesare_-_1860.jpg",
        "a88b13f63076240d739def5712b46d2bda9cac0c10c369d79e2273caae5dd913",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A merchant.",
    ),
    (
        "people/rector.jpg",
        "Habito ordinario et commune a tutta la nobilta Venetiana - Vecellio Cesare - 1860.jpg",
        "8/80/Habito_ordinario_et_commune_a_tutta_la_nobilta_Venetiana_-_Vecellio_Cesare_-_1860.jpg",
        "13c85dd9e537b8da634bc40d46d1fe61a59767bc365cdee87c621182d3b27b5f",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "The Rector of Ragusa: a noble in a black toga.",
    ),
    (
        "people/prelate.jpg",
        "Habito de Cardinali - Vecellio Cesare - 1860.jpg",
        "6/67/Habito_de_Cardinali_-_Vecellio_Cesare_-_1860.jpg",
        "8e4e2c4b6426cf857c3f59aef7623356d45d79c4564f6adef5a88a1ee1fc794d",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "The envoy of the Pope, and the Franciscan apothecary.",
    ),
    (
        "people/nobleman.jpg",
        "Gentil'huomo moderno Napolitano - Vecellio Cesare - 1860.jpg",
        "5/5a/Gentil%27huomo_moderno_Napolitano_-_Vecellio_Cesare_-_1860.jpg",
        "3d29e07667dc958d7b3263c5ec124f9e978be0631ffe776f73b0b2852fa22a5b",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A nobleman of Naples.",
    ),
    (
        "people/old_woman.jpg",
        "Donne di Venetia attempate et dismesse - Vecellio Cesare - 1860.jpg",
        "8/82/Donne_di_Venetia_attempate_et_dismesse_-_Vecellio_Cesare_-_1860.jpg",
        "5c457eba8e13c65a0da95873f7712747251bd47f7d3863e8ad0450a16f2abc55",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "An old woman.",
    ),
    (
        "people/sailor.jpg",
        "Galeotti, o falila chiamati, scritti per il dominio Veneto a tempo di guerra - Vecellio Cesare - 1860.jpg",
        "4/41/Galeotti%2C_o_falila_chiamati%2C_scritti_per_il_dominio_Veneto_a_tempo_di_guerra_-_Vecellio_Cesare_-_1860.jpg",
        "d605ebb5a693d31ad71f28b5a676794c3d6a05d2210c0135dd5558a6d78ba186",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A sailor of the galleys.",
    ),
    (
        "people/greek.jpg",
        "Nobile Greco - Vecellio Cesare - 1860.jpg",
        "5/53/Nobile_Greco_-_Vecellio_Cesare_-_1860.jpg",
        "5ec85b382a941e6326be8ba314f604edae7512ed5beb47c826acde725d9c0acc",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A Greek noble of Corfu.",
    ),
    (
        "people/daughter.jpg",
        "Donzella Venetiana - Vecellio Cesare - 1860.jpg",
        "6/6f/Donzella_Venetiana_-_Vecellio_Cesare_-_1860.jpg",
        "e3cdf3ebe8dde894f5642cd38daa426fbd193649ad66c5e1a5e25944c879894a",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "Katarina: a young woman.",
    ),
    (
        "people/artisan.jpg",
        "Schiavone o vero Dalmatino - Vecellio Cesare - 1860.jpg",
        "3/3a/Schiavone_o_vero_Dalmatino_-_Vecellio_Cesare_-_1860.jpg",
        "3c10df4e806ea3c4af2192c87afde27dccc36002de64bb28ef17aeed1d7a5f20",
        (0.085, 0.13, 0.425, 0.86),
        VECELLIO,
        1590,
        "A Dalmatian man.",
    ),
]


def download(upload_path: str, sha256: str) -> pathlib.Path:
    """Download the original (once) and check its hash."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    target = CACHE_DIR / urllib.parse.unquote(pathlib.PurePosixPath(upload_path).name)
    if not target.exists():
        url = UPLOAD + upload_path
        print(f"Downloading {url}")
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=120) as response:
            target.write_bytes(response.read())

        # NOTE (mristin):
        # Wikimedia limits the rate of the downloads.
        time.sleep(3)

    digest = hashlib.sha256(target.read_bytes()).hexdigest()
    if digest != sha256:
        target.unlink()
        raise RuntimeError(f"The SHA-256 of {target.name} is {digest}, but we expected {sha256}")
    return target


def prepare(
    source: pathlib.Path,
    crop: Optional[Tuple[float, float, float, float]],
    target: pathlib.Path,
) -> Tuple[int, int]:
    """Crop, tint and shrink the picture; return its size."""
    image = Image.open(source).convert("L")
    if crop is not None:
        width, height = image.size
        image = image.crop(
            (
                int(crop[0] * width),
                int(crop[1] * height),
                int(crop[2] * width),
                int(crop[3] * height),
            )
        )
    image = ImageOps.autocontrast(image, cutoff=1)
    tinted = ImageOps.colorize(image, black=INK, white=PAPER)
    tinted.thumbnail((PICTURE_SIZE, PICTURE_SIZE), Image.LANCZOS)
    target.parent.mkdir(parents=True, exist_ok=True)
    tinted.save(target, quality=86, optimize=True)
    return tinted.size


def main() -> int:
    manifest = []
    for target_path, title, upload_path, sha256, crop, work, year, shows in PICTURES:
        source = download(upload_path, sha256)
        target = PERIOD_DIR / target_path
        size = prepare(source, crop, target)
        print(f"Prepared {target.relative_to(REPO_ROOT)} ({size[0]} x {size[1]})")
        manifest.append(
            {
                "file": target_path,
                "shows": shows,
                "work": work,
                "year": year,
                "source": COMMONS + "File:" + urllib.parse.quote(title.replace(" ", "_")),
                "original": UPLOAD + upload_path,
                "original_sha256": sha256,
                "license": "Public domain (Wikimedia Commons)",
                "altered": (
                    "cropped, tinted to ink on paper, shrunk"
                    if crop is not None
                    else "tinted to ink on paper, shrunk"
                ),
            }
        )

    (PERIOD_DIR / "manifest.json").write_text(
        json.dumps(manifest, indent=4, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"Wrote {len(manifest)} picture(s) and assets/period/manifest.json")
    return 0


if __name__ == "__main__":
    sys.exit(main())
