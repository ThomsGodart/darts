# Spec : Session partagée entre téléphones + mode écran

Status: ready-for-human  
Source: demande utilisateur 2026-10-06 (identifiants Supabase fournis ; « un téléphone en mode écran et l’autre pour taper »)  
Vocabulary: **Share**, **Code**, **Guest**, **Screen mode** — see `CONTEXT.md`. Decision: `docs/adr/0006`.

## Tickets

| # | File | Focus |
|---|---|---|
| 01 | [issues/01-share-and-screen-mode.md](issues/01-share-and-screen-mode.md) | Partage par code + mode écran (fait) |
| 02 | [issues/02-device-validation.md](issues/02-device-validation.md) | Validation sur deux téléphones (humain) |

## Problem Statement

Le téléphone qui sert à saisir est en main ; personne ne voit le score de loin. Les joueurs veulent poser un téléphone près de la cible comme tableau, et saisir sur un autre.

## Solution

Depuis une partie, « Partager la session » affiche un code à six chiffres. Sur l’autre téléphone, « Rejoindre une session » à l’accueil, puis le code : il affiche la même partie, clavier masqué (mode écran), et peut saisir lui aussi s’il réaffiche le clavier. Le clavier se masque aussi sur n’importe quel téléphone, partagé ou non. Rien n’est stocké en ligne ; sans réseau l’app marche comme avant.

## Out of Scope

- Comptes, historique ou stats synchronisés entre appareils
- Session qui survit à l’arrêt du téléphone qui partage sans qu’un autre l’ait rejointe
- Fusion de deux saisies simultanées (une seule est gardée)
- QR code / lien pour rejoindre
