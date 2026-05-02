# Projet CPU 8 bits — Logisim Evolution

**Année :** 2025-2026  
**Auteurs :** EB • DO

---

## Description

Conception d'un processeur 8 bits entièrement fonctionnel sur **Logisim Evolution**, construit étape par étape depuis les portes logiques élémentaires jusqu'à un CPU complet supportant ROM, RAM et branchements inconditionnels.

Le fichier `cpu8.circ` contient **17 circuits imbriqués**. Le jeu d'instructions est encodé sur **14 bits** et supporte :
- L'affectation immédiate d'une valeur dans un registre
- Les opérations registre-à-registre : **ADD, AND, OR, XOR**
- Le chargement depuis la RAM (**LOAD**)
- Le stockage en RAM (**STORE**)
- Le saut inconditionnel (**JUMP**)

Les registres R0 à R3 manipulent des données sur **8 bits non signés**.

---

## Structure du projet

```
cpu8/
├── cpu8.circ               # Fichier principal Logisim (17 sous-circuits)
├── rapport_cpu8.pdf        # Rapport de projet (version PDF)
├── tests/
│   ├── _README.md                    # Guide des tests
│   ├── rom_etape7.hex                # Programme ROM – Étape 7 (CPU basique)
│   ├── rom_etape8_sans_jump.hex      # Programme ROM – Étape 8 (avec RAM)
│   ├── rom_etape9_avec_jump.hex      # Programme ROM – Étape 9 (avec JUMP)
│   ├── ram_etape8_init.hex           # État initial RAM – Étape 8
│   └── ram_etape9_init.hex           # État initial RAM – Étape 9
└── en/
    ├── README.md                     # English version of this README
    └── rapport_cpu8_en.md            # Project report (English translation)
```

---

## Architecture des sous-circuits

| Étape | Sous-circuit | Rôle |
|-------|-------------|------|
| 1 | AND_8_bits, OR_8_bits, XOR_8_bits | Opérations logiques bit à bit |
| 1 | UL_setp_2 | Unité logique combinée |
| 2 | Additionneur_1_bit | Additionneur 1 bit avec retenue |
| 2 | ADDITIONNEUR_8_bits | Additionneur 8 bits (ripple carry) |
| 3 | UAL | Unité Arithmétique et Logique complète |
| 4 | Registre_8_bits | Registre individuel 8 bits (8× bascule D) |
| 4 | Banc_4_Registres | Banc de 4 registres (R0–R3) |
| 5 | UAL_ET_BANC | UAL + banc de registres en boucle fermée |
| 6 | Pointeur_Programme | Compteur programme (PC) |
| 6 | Decodage_Instruction | Décodeur d'instructions combinatoire |
| 6 | Etape7_ROM | Processeur complet avec ROM |
| 7 | ETAPE8_RAM | Extension RAM (LOAD/STORE) |
| 8 | Pointeur_Programme_JMP | PC avec support JUMP |
| 8 | Decodage_Instruction_JUMP | Décodeur étendu (JUMP) |
| 8 | ETAPE9_JUMP | Processeur final complet |

---

## Format d'instruction (14 bits)

| Bit 13 | Bits 12-11 | Bits 10-9 | Bits 8-1 | Bit 0 |
|--------|-----------|-----------|---------|-------|
| MODE (1=immédiat) | OP (ADD/AND/OR/XOR) | ADDR_RES | DATA ou ADDR_OP1+OP2 | WE |

---

## Prérequis & Utilisation

1. Télécharger [Logisim Evolution](https://github.com/logisim-evolution/logisim-evolution/releases)
2. Ouvrir `cpu8.circ`
3. Charger le fichier `.hex` correspondant dans la ROM (et dans la RAM pour les étapes 8/9)
4. Lancer la simulation avec l'horloge

---

## Rapport

Le rapport complet détaille chaque sous-circuit, son interface, son fonctionnement et ses tests de vérification.  
→ `rapport_cpu8.pdf` (Français) | `en/rapport_cpu8_en.md` (English)
