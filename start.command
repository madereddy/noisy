#!/bin/bash
# Noisy - Traffic Noise Generator (macOS)

echo ""
echo "  ========================================"
echo "   NOISY - Traffic Noise Generator"
echo "  ========================================"
echo ""

# Move to script directory
cd "$(dirname "$0")"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "  [ERREUR] Python 3 n'est pas installe."
    echo "  Telecharge-le ici : https://www.python.org/downloads/"
    echo ""
    read -p "  Appuie sur Entree pour fermer..."
    exit 1
fi

# Create venv if missing
if [ ! -d "venv" ]; then
    echo "  [1/3] Creation de l'environnement virtuel..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "  [ERREUR] Impossible de creer le venv."
        read -p "  Appuie sur Entree pour fermer..."
        exit 1
    fi
fi

# Activate venv
source venv/bin/activate

# Install deps if needed
if [ ! -f "venv/.deps_installed" ]; then
    echo "  [2/3] Installation des dependances..."
    pip install -r requirements.txt --quiet
    if [ $? -ne 0 ]; then
        echo "  [ERREUR] Installation echouee."
        read -p "  Appuie sur Entree pour fermer..."
        exit 1
    fi
    touch venv/.deps_installed
else
    echo "  [2/3] Dependances deja installees."
fi

echo "  [3/3] Demarrage de Noisy + Dashboard..."
echo ""
echo "  Dashboard : http://localhost:8080"
echo "  Appuie sur Ctrl+C pour arreter."
echo ""

python noisy.py --dashboard "$@"

echo ""
read -p "  Appuie sur Entree pour fermer..."
