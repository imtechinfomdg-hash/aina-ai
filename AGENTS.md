# Directives Architecturales pour Aina

L'application "Aina" est une application Android de santé infantile et de secourisme local-first pour Madagascar.

## Principes Fondamentaux (Stricts)
1. **100% Local-First / Hors-Ligne** : L'application est 100% autonome et fonctionne hors-ligne. Exclusion totale de services cloud (pas de Firebase, pas d'API distantes, pas de bases de données cloud).
2. **IA Embarquée** : Le modèle utilisé est Llama-3.2-1B-Instruct au format GGUF chargé localement.
3. **Sécurité et Confidentialité** : Toutes les données médicales sont stockées et chiffrées localement sur l'appareil. Aucun stockage de mémoire à long terme déporté, aucune synchronisation cloud invisible.
4. **Gratuité et Indépendance** : Il est strictement interdit d'ajouter des modules, du code, des dépendances ou des commentaires techniques liés à des serveurs distants ou à des fonctionnalités payantes.
5. **Cadre Médical OMS** : Toute la logique médicale de l'IA doit être bridée par le contexte des directives officielles PCIME de l'OMS.
6. **Multilingue** : L'application est multilingue (Malgache, Français, Anglais). Les textes légaux du RGPD sont uniquement en Français et en Anglais.

## Développement
- Produire un code Flutter propre, modulaire, documenté et sans omission.
- Toujours privilégier des bibliothèques locales (`sqflite`, `flutter_secure_storage`, `local_auth`).
- Ne jamais implémenter de requêtes réseau (`http`, `dio`, etc.) pour des fonctionnalités métiers ou d'inférence.
