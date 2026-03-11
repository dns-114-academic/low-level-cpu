# Low-level Programming & CPU Architecture

**TP + Projet Architecture & Cyberdef** | école d'ingénieurs — Jan.–Avr. 2026 | MASM x86-32, Logisim

## Présentation

Deux projets complémentaires explorant le bas niveau : langage d'assemblage Intel x86 32 bits (MASM) sous Windows, et conception d'un micro-processeur minimal en simulation Logisim.

---

## Partie 1 — Assemblage x86 MASM (en binôme)

TP progressif sur les instructions x86-32 (sans macros MASM ni `INVOKE` dans les segments de code), suivi d'un projet applicatif.

### Exercices
- Instructions de base : registres, boucles, conditions, appels de fonctions
- Manipulation de la pile, appels système Win32

### Projet — Clone de `DIR\S`

Listage récursif des fichiers d'un disque à partir d'un point d'entrée, en MASM pur :

| Version | Détail |
|:---|:---|
| **CLI** | Affichage dans le terminal, récursion via la pile d'appel |
| **GUI** | Interface graphique Windows : `DialogBoxParam`, zone de saisie, listing scrollable |

API Win32 utilisées : `FindFirstFile`, `FindNextFile`, `CreateWindowEx`, ...

---

## Partie 2 — Mini CPU avec Logisim

Conception et simulation d'un micro-processeur minimal, implémentation des composants fondamentaux :

| Composant | Détail |
|:---|:---|
| **ALU** | ADD, SUB, AND, OR, XOR, NOT — flags Zero, Carry, Overflow, Sign |
| **Banc de registres** | Registres généraux 8/16 bits, lecture/écriture synchronisées |
| **Mémoire** | ROM (programme) + RAM (données), bus adresses/données |
| **Unité de contrôle** | Décodage instructions, signaux de contrôle, cycle Fetch-Decode-Execute |
| **Jeu d'instructions** | LOAD/STORE/MOV, arithmétique, logique, sauts conditionnels |

- Programmes de test : boucle compteur, calcul simple
- Vérification des flags et simulation du pipeline

## Stack

`MASM x86-32` · `Win32 API` · `Logisim` · `makefile.bat`

---

*Projet académique — école d'ingénieurs*
