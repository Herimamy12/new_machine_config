# New Machine Configuration Scripts

Scripts automatisés pour configurer rapidement une nouvelle machine Debian 13 (Trixie) avec tous les outils de développement essentiels.

## 📋 Table des matières

- [Aperçu](#aperçu)
- [Prérequis](#prérequis)
- [Installation](#installation)
- [Scripts disponibles](#scripts-disponibles)
- [Logiciels installés](#logiciels-installés)
- [Configuration avancée](#configuration-avancée)
- [Logs et sauvegarde](#logs-et-sauvegarde)
- [Dépannage](#dépannage)
- [License](#license)

## 🎯 Aperçu

Ce projet contient des scripts Bash pour automatiser l'installation et la configuration d'une nouvelle machine de développement sous Debian 13. Les scripts sont **idempotents** (peuvent être exécutés plusieurs fois sans effets indésirables) et incluent un système de **logging complet**.

## ✅ Prérequis

- Debian 13 (Trixie) fraîchement installé
- Connexion Internet active
- Droits sudo configurés
- Pour `init_ssh.sh` : VirtualBox Guest Additions installées (si vous utilisez une VM)

## 🚀 Installation

1. **Cloner le repository** :
```bash
git clone https://github.com/<votre-username>/new_machine_config.git
cd new_machine_config
```

2. **Rendre les scripts exécutables** :
```bash
chmod +x init.sh init_ssh.sh
```

3. **Exécuter le script principal** :
```bash
./init.sh
```

4. **(Optionnel) Configurer les clés SSH** :
```bash
./init_ssh.sh
```

## 📜 Scripts disponibles

### `init.sh`
Script principal qui installe et configure tous les outils de développement.

**Fonctionnalités** :
- ✅ Vérifications d'idempotence (ne réinstalle pas si déjà présent)
- 📝 Logging complet avec horodatage
- 💾 Sauvegarde automatique des fichiers de configuration
- ⚠️ Gestion d'erreurs robuste (`set -euo pipefail`)
- 🎨 Messages informatifs avec niveaux de log (INFO, SUCCESS, WARNING, ERROR)

### `init_ssh.sh`
Script pour copier les clés SSH depuis un dossier partagé VirtualBox.

**Fonctionnalités** :
- 🔒 Définit les permissions correctes automatiquement
- 💾 Sauvegarde des clés existantes avant remplacement
- ✅ Vérification de l'existence des fichiers source
- 📝 Logging des opérations

## 📦 Logiciels installés

### Navigateurs Web
- **Google Chrome** - Navigateur web populaire
- **Brave Browser** - Navigateur axé sur la confidentialité

### Outils de développement
- **Git** - Contrôle de version
- **VS Code** - Éditeur de code
- **Node.js & NPM** - Environnement JavaScript
- **Docker** - Conteneurisation (avec Docker Compose)

### Environnement C/C++
- **build-essential** - Compilateurs GCC/G++
- **GDB** - Débogueur
- **CMake** - Système de build
- **Valgrind** - Détection de fuites mémoire

### Outils Python
- **Norminette** - Vérificateur de norme 42
- **Flake8** - Linter Python

### Shell
- **Zsh** - Shell avancé
- **Oh-My-Zsh** - Framework de configuration Zsh

## ⚙️ Configuration avancée

### Personnalisation du thème Zsh
Pendant l'exécution, le script vous propose de choisir un thème Oh-My-Zsh. Thèmes populaires :
- `agnoster` - Thème avec infos Git
- `robbyrussell` - Thème par défaut, minimaliste
- `bira` - Thème avec temps d'exécution
- `ys` - Thème compact et informatif

### Configuration Git
Le script vous invite à configurer votre identité Git globale. Vous pouvez également le faire manuellement :
```bash
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@example.com"
```

### Docker sans sudo
Après l'installation, vous êtes ajouté au groupe `docker`. Pour utiliser Docker sans `sudo`, **déconnectez-vous et reconnectez-vous** ou redémarrez la machine.

## 📊 Logs et sauvegarde

### Fichiers de log
Chaque exécution génère un fichier de log avec horodatage :
```
setup_YYYYMMDD_HHMMSS.log
```

Le log contient :
- Toutes les opérations effectuées
- Les erreurs et avertissements
- Les timestamps de chaque action

### Sauvegardes
Les fichiers de configuration modifiés sont sauvegardés dans :
```
~/.config_backups/YYYYMMDD_HHMMSS/
```

Pour `init_ssh.sh`, les clés SSH existantes sont sauvegardées dans :
```
~/.ssh_backup_YYYYMMDD_HHMMSS/
```

## 🔧 Dépannage

### Le script échoue lors de l'installation de Docker
**Problème** : Le dépôt Debian 13 (Trixie) n'est peut-être pas encore disponible.

**Solution** : Modifier manuellement le fichier `/etc/apt/sources.list.d/docker.list` et remplacer `trixie` par `bookworm`.

### Zsh ne se charge pas après l'installation
**Problème** : Le shell par défaut n'a pas été changé.

**Solution** : Déconnectez-vous et reconnectez-vous, ou exécutez :
```bash
chsh -s $(which zsh)
```

### Erreur "Permission denied" avec Docker
**Problème** : L'utilisateur n'est pas encore effectivement dans le groupe docker.

**Solution** : Déconnectez-vous et reconnectez-vous, ou exécutez :
```bash
newgrp docker
```

### VirtualBox Shared Folder non accessible
**Problème** : Le dossier partagé `/media/sf_.ssh` n'existe pas.

**Solution** :
1. Installer VirtualBox Guest Additions
2. Configurer le dossier partagé dans VirtualBox
3. Ajouter l'utilisateur au groupe `vboxsf` : `sudo usermod -aG vboxsf $USER`

## 🎓 Utilisation recommandée

1. **Première installation** : Exécutez `init.sh`
2. **Après redémarrage** : Si nécessaire, configurez vos clés SSH avec `init_ssh.sh`
3. **Personnalisation** : Modifiez les scripts selon vos besoins spécifiques

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Ouvrir une issue pour signaler un bug
- Proposer des améliorations
- Soumettre une pull request

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.