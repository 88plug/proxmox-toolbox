ifconfig | grep inet | cut -d: -f2 | awk '{print $2}' | grep -v -E "^127\.|^172\.|^192\.168\.|^10\." | xargs
