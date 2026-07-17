# Configuration des Widgets iOS Milo

Les fichiers du widget iOS ont été créés dans le dossier `ios/MiloWidget/`. 
Pour finaliser l'installation, suivez ces étapes dans Xcode :

## Étapes de configuration

### 1. Ouvrir le projet dans Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Ajouter la Widget Extension
1. Dans Xcode, cliquez sur **File > New > Target**
2. Sélectionnez **Widget Extension**
3. Nommez-la `MiloWidget`
4. Décochez "Include Configuration Intent"
5. Cliquez sur **Finish**

### 3. Remplacer les fichiers générés
1. Supprimez les fichiers générés automatiquement dans le dossier MiloWidget
2. Copiez les fichiers de `ios/MiloWidget/` vers le groupe MiloWidget dans Xcode

### 4. Configurer l'App Group
1. Sélectionnez le target **Runner** > **Signing & Capabilities**
2. Cliquez sur **+ Capability** > **App Groups**
3. Ajoutez `group.com.milo.milo`
4. Répétez pour le target **MiloWidgetExtension**

### 5. Configurer le Bundle Identifier
Le widget doit avoir un identifiant de la forme :
- App principale : `com.milo.milo`
- Widget : `com.milo.milo.MiloWidget`

### 6. Build et test
1. Sélectionnez un simulateur iOS
2. Build le projet (⌘B)
3. Sur l'écran d'accueil du simulateur, faites un appui long et ajoutez le widget Milo

## Fonctionnalités des widgets

### Widget petit (2x2)
- Affiche le titre de la piste en cours
- Boutons de contrôle (précédent, play/pause, suivant)

### Widget moyen (4x2)
- Affiche l'artwork, le titre et l'artiste
- Boutons de contrôle complets
- Design néo-brutaliste Milo

## Notes
- Les widgets se mettent à jour automatiquement via `home_widget`
- Les couleurs utilisent la palette Milo (jaune vif, crème, noir profond)
- Les interactions sont gérées via deep links vers l'application
