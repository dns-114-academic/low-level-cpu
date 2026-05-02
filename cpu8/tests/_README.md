# Guide de test — Processeur 8 bits (cpu8.circ)

Ouvrir `cpu8.circ` dans **Logisim Evolution v4.0.0**.  
Le circuit principal est **ETAPE9_JUMP** (menu déroulant en haut à gauche).

---

## TEST 1 — Unités logiques bit-à-bit

**Circuits :** `AND_8_bits`, `OR_8_bits`, `XOR_8_bits`, `UL_step_2`  
**Méthode :** Ouvrir chaque circuit, forcer manuellement les broches d'entrée.

| Entrée 1 | Entrée 2 | AND attendu | OR attendu | XOR attendu |
|----------|----------|-------------|------------|-------------|
| 0xB3     | 0xCA     | 0x82        | 0xFB       | 0x79        |
| 0xFF     | 0x00     | 0x00        | 0xFF       | 0xFF        |
| 0x0F     | 0xF0     | 0x00        | 0xFF       | 0xFF        |

---

## TEST 2 — Additionneur 1 bit

**Circuit :** `ADDITIONNEUR_1_bit`  
**Méthode :** Forcer (a, b, Rin) et observer (somme, Rout).

| Rin | a | b | somme | Rout |
|-----|---|---|-------|------|
| 0   | 0 | 0 | 0     | 0    |
| 0   | 1 | 1 | 0     | 1    |
| 1   | 1 | 1 | 1     | 1    |
| 1   | 0 | 1 | 0     | 1    |

---

## TEST 3 — Additionneur 8 bits

**Circuit :** `ADDITIONNEUR_8_bits`

| a    | b    | Rin | somme | Rout |
|------|------|-----|-------|------|
| 0x05 | 0x00 | 0   | 0x05  | 0    |
| 0xFF | 0x01 | 0   | 0x00  | 1    |
| 0x0A | 0x05 | 0   | 0x0F  | 0    |

---

## TEST 4 — UAL 8 bits

**Circuit :** `UAL_8_BITS`  
**Broche OP :** 2 bits (00=ADD, 01=AND, 10=OR, 11=XOR)

| A    | B    | OP | Résultat |
|------|------|----|----------|
| 0x05 | 0x00 | 00 | 0x05     |
| 0x05 | 0x00 | 01 | 0x00     |
| 0x00 | 0x05 | 10 | 0x05     |
| 0x05 | 0x05 | 11 | 0x00     |

---

## TEST 5 — Banc de registres

**Circuit :** `BANC_4_REGISTRES`

1. ADDR_RES=01 (R1), WE=1, E=0x05, Clock↑ → R1=0x05, sorties inchangées
2. ADDR_OP1=01, ADDR_OP2=00 → A=0x05, B=0x00

---

## TEST 6 — ETAPE7_ROM (processeur sans RAM ni JUMP)

**Circuit :** `ETAPE7_ROM`  
**ROM :** 14 bits — charger le fichier `rom_etape7.hex`  
**Procédure :** Clic droit sur la ROM → *Load Image* → sélectionner `rom_etape7.hex`

Programme chargé :

| Adresse | Instruction    | Hex  |
|---------|----------------|------|
| 0x00    | R1 = 5         | 220B |
| 0x01    | R2 = R1 + R0   | 0421 |
| 0x02    | R3 = R1 XOR R2 | 1E25 |
| 0x03    | R0 = R2 AND R3 | 0847 |
| 0x04    | R1 = R0 OR R2  | 1205 |

**Résultats attendus après 5 coups d'horloge :**

| Registre | Valeur |
|----------|--------|
| R0       | 0x00   |
| R1       | 0x05   |
| R2       | 0x05   |
| R3       | 0x00   |

---

## TEST 7 — ETAPE8_RAM (avec LOAD/STORE)

**Circuit :** `ETAPE8_RAM`  
**ROM :** 16 bits — charger `rom_etape8_sans_jump.hex`  
**RAM init :** charger `ram_etape8_init.hex` dans la RAM (RAM[0x04] = 3)

Programme chargé :

| Adresse | Instruction          | Hex  |
|---------|----------------------|------|
| 0x00    | LOAD R1, 5           | 4416 |
| 0x01    | LOAD R2, @0x04 (RAM) | 8812 |
| 0x02    | R3 = R1 + R2         | 0C4A |
| 0x03    | STORE @0x08, R3      | CC20 |
| 0x04    | R0 = R1 XOR R2       | 304A |

**Résultats attendus après 5 coups d'horloge :**

| Registre / Mémoire | Valeur            |
|--------------------|-------------------|
| R1                 | 0x05 (5)          |
| R2                 | 0x03 (3)          |
| R3                 | 0x08 (8)          |
| R0                 | 0x06 (5 XOR 3 = 6)|
| RAM[0x08]          | 0x08 (8)          |

---

## TEST 8 — ETAPE9_JUMP (avec instruction JUMP)

**Circuit :** `ETAPE9_JUMP`  
**ROM :** 16 bits — charger `rom_etape9_avec_jump.hex`  
**RAM init :** charger `ram_etape9_init.hex` dans la RAM (RAM[0x04] = 3)

Programme chargé :

| Adresse | Instruction          | Hex  |
|---------|----------------------|------|
| 0x00    | LOAD R1, 5           | 4416 |
| 0x01    | LOAD R2, @0x04 (RAM) | 8812 |
| 0x02    | R3 = R1 + R2         | 0C4A |
| 0x03    | JUMP                 | 0007 |
| 0x04    | STORE @0x08, R3      | CC20 | ← sautée
| 0x05    | R0 = R1 XOR R2       | 304A |

**Résultats attendus :**

| Registre / Mémoire | Valeur                          |
|--------------------|---------------------------------|
| R1                 | 0x05                            |
| R2                 | 0x03                            |
| R3                 | 0x08                            |
| R0                 | 0x06 (exécuté après le saut)    |
| RAM[0x08]          | inchangé (STORE sautée)         |
| PC après JUMP      | adresse cible (vérifier signal) |

---

## Notes importantes

- Après *Load Image*, faire **Simulate → Reset Simulation** puis relancer l'horloge.
- La ROM **doit** avoir `Data Bit Width = 14` pour ETAPE7, et `= 16` pour ETAPE8 et ETAPE9.
- Pour la RAM, vérifier que `Data Bit Width = 8` et `Address Bit Width = 8`.
- Utiliser **Simulate → Tick Once** (Ctrl+T) pour avancer cycle par cycle.
