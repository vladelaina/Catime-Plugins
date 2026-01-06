# Guide des Plugins Catime

## Qu'est-ce qu'un Plugin ?

Un plugin est un fichier de script qui affiche du contenu personnalisé dans la fenêtre Catime. Par exemple :

- 📺 Vos statistiques vidéo Bilibili/YouTube
- 📈 Indices NASDAQ et S&P 500 en temps réel
- 🌤️ Prévisions météo locales
- 🌐 Statistiques de trafic de votre site web
- 💻 État du serveur
- ……

**Concept clé : Toutes les données que votre script peut récupérer peuvent être affichées dans la fenêtre Catime !**

De plus, ces données peuvent être placées n'importe où sur votre écran et redimensionnées à volonté, comme l'affichage de l'heure de Catime — toujours visibles sans bloquer d'autres fenêtres.

**Comment ça marche :** Votre script écrit dans `output.txt` → Catime le lit → L'affiche dans la fenêtre. C'est aussi simple !

> **Conseil :** Assurez-vous d'avoir installé l'environnement d'exécution requis (par exemple, Python, Node.js, etc.)

---

## Démarrage Rapide en 30 Secondes

Vous ne voulez pas écrire de code ? Essayez manuellement d'abord :

### Étape 1 : Ouvrir le Dossier des Plugins

Clic droit sur l'icône Catime → `Plugins` → `Ouvrir le Dossier des Plugins`

### Étape 2 : Modifier output.txt

Trouvez (ou créez) `output.txt` dans le dossier et écrivez quelque chose :

```
Bonjour, Catime !
Ceci est mon premier message 🎉
```

### Étape 3 : Afficher le Contenu du Fichier

Clic droit sur l'icône Catime → `Plugins` → `Afficher le Fichier Plugin`

**Terminé !** La fenêtre Catime affiche maintenant votre contenu.

> C'est l'essence des plugins : **Ce que vous écrivez dans output.txt apparaît dans la fenêtre**.
> Les scripts de plugins automatisent simplement ce processus.

---

## Créez Votre Premier Plugin en 3 Étapes

### Étape 1 : Ouvrir le Dossier des Plugins

Clic droit sur l'icône Catime → `Plugins` → `Ouvrir le Dossier des Plugins`

### Étape 2 : Créer un Fichier de Script

Créez un nouveau fichier dans ce dossier, par exemple `hello.py` :

```python
with open('output.txt', 'w', encoding='utf-8') as f:
    f.write('Bonjour, Catime !')
```

**Juste quelques lignes !**

### Étape 3 : Exécuter le Plugin

1. Clic droit sur l'icône Catime
2. `Plugins` → Cliquez sur `hello.py`
3. La première fois, il demandera si vous faites confiance, cliquez sur "Faire Confiance et Exécuter"

**Terminé !** La fenêtre affiche maintenant "Bonjour, Catime !"

---

## Point Clé

Ce que votre script écrit dans `output.txt`, Catime l'affiche. L'affichage se rafraîchit automatiquement quand le fichier est mis à jour.

---

## Balises Spéciales (Optionnel)

Utilisez ces balises si nécessaire :

| Balise | Fonction | Exemple |
|--------|----------|---------|
| `<md></md>` | Activer le formatage Markdown | `<md>**gras** *italique*</md>` |
| `<catime></catime>` | Afficher le temps du minuteur | `En cours <catime></catime>` → `En cours 00:05:30` |
| `<exit>N</exit>` | Fermer automatiquement le plugin après N secondes | `<exit>5</exit>` → ferme après 5 secondes |
| `<fps:N>` | Rafraîchir N fois par seconde (défaut 2, plage 1-100) | `<fps:10>` → 10 rafraîchissements par seconde |
| `<color:valeur></color>` | Définir la couleur du texte (supporte les dégradés) | `<color:#FF0000>rouge</color>` |
| `<font:chemin></font>` | Définir la police (chemin du fichier de police) | `<font:C:\Windows\Fonts\comic.ttf>amusant</font>` |
| `![](chemin)` | Afficher une image (chemin local ou URL) | `![](meteo.png)` ou `![](https://example.com/img.png)` |
| `![LxH](chemin)` | Afficher une image avec une taille spécifique | `![100x50](logo.png)` ou `![200](logo.png)` (largeur seulement) |

> **À propos de `<fps:N>` :** Le rafraîchissement par défaut est toutes les 500ms (2 fois par seconde). Pour des données qui se mettent à jour rapidement, augmentez le taux jusqu'à `<fps:100>` (100 fois par seconde).

> **À propos de la couleur et de la police :** Ces balises fonctionnent seules (pas besoin de `<md>`) et peuvent être imbriquées. Les chemins de police supportent les chemins absolus, les variables d'environnement ou les chemins relatifs au répertoire du plugin.

---

## Langages Supportés

Python, PowerShell, Batch, JavaScript... même Shell, Ruby, PHP, Lua et **plus de 90 langages** sont supportés ! Tant que vous avez l'interpréteur installé, n'importe quel langage fonctionne.

> **Recommandé :** Utilisez **PowerShell (.ps1)** ou **Batch (.bat)** — intégrés à Windows, aucune installation nécessaire, utilisation des ressources plus faible.

---

## Est-ce Sécurisé ?

Lors de la première exécution d'un plugin, Catime demandera :

- **Annuler** = Ne pas exécuter
- **Exécuter Une Fois** = Exécuter cette fois seulement, demandera à nouveau la prochaine fois
- **Faire Confiance et Exécuter** = Toujours exécuter automatiquement

Si vous modifiez un fichier de plugin, Catime demandera à nouveau pour prévenir toute altération.

---

## FAQ

### Le plugin n'affiche pas de contenu ?

Vérifiez :
- Le chemin du fichier est correct (le script doit écrire dans `output.txt` dans le même répertoire)
- L'interpréteur est installé (par exemple, les scripts Python nécessitent Python)

### Comment arrêter un plugin ?

Clic droit sur l'icône → Plugins → Cliquez à nouveau sur le plugin en cours (marqué avec ✓)

### Faut-il redémarrer après modification ?

Non ! Catime détecte automatiquement les changements et relance le plugin (rechargement à chaud).

### Puis-je exécuter plusieurs plugins ?

Non, un seul à la fois. Cliquez sur un autre plugin pour changer ; l'actuel s'arrête automatiquement.

### Les plugins continuent-ils après la fermeture de Catime ?

Non. Catime arrête tous les processus de plugins à la fermeture.

---

## Notes

⚠️ **Évitez les sous-processus imbriqués**

Utilisez un seul processus pour accomplir les tâches. Si votre script lance des sous-processus (par exemple, en utilisant `start` dans `.bat`), ils peuvent ne pas être nettoyés correctement.

---

**C'est tout ! Maintenant, allez créer votre premier plugin !** 🚀
