# 3x-ui rootless iOS environment
export XUI_BIN_FOLDER=/var/jb/usr/local/x-ui/bin
export XUI_DB_FOLDER=/var/jb/etc/x-ui
export XUI_LOG_FOLDER=/var/jb/var/log/x-ui
export XRAY_LOCATION_ASSET=/var/jb/usr/local/x-ui/bin

case ":$PATH:" in
    *:/var/jb/usr/bin:*) ;;
    *) export PATH="/var/jb/usr/bin:$PATH" ;;
esac
