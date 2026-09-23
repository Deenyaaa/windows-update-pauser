import ctypes
import logging
import os
import sys
import winreg
from datetime import datetime, timedelta, timezone

PAUSE_DAYS = 14
REG_PATH = r"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
LOG_DIR = os.path.join(os.environ.get("ProgramData", r"C:\ProgramData"), "PostponeWinUpdate")

os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(LOG_DIR, "log.txt"),
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    encoding="utf-8",
)


def is_admin():
    try:
        return bool(ctypes.windll.shell32.IsUserAnAdmin())
    except Exception:
        return False


def main():
    if not is_admin():
        logging.error("Нет прав администратора")
        return 1

    fmt = "%Y-%m-%dT%H:%M:%SZ"
    now = datetime.now(timezone.utc)
    start = now.strftime(fmt)
    expiry = (now + timedelta(days=PAUSE_DAYS)).strftime(fmt)

    values = {
        "PauseUpdatesStartTime": start,
        "PauseUpdatesExpiryTime": expiry,
        "PauseFeatureUpdatesStartTime": start,
        "PauseFeatureUpdatesEndTime": expiry,
        "PauseQualityUpdatesStartTime": start,
        "PauseQualityUpdatesEndTime": expiry,
    }

    try:
        with winreg.CreateKeyEx(
            winreg.HKEY_LOCAL_MACHINE,
            REG_PATH,
            0,
            winreg.KEY_SET_VALUE | winreg.KEY_WOW64_64KEY,
        ) as key:
            for name, value in values.items():
                winreg.SetValueEx(key, name, 0, winreg.REG_SZ, value)
    except OSError:
        logging.exception("Ошибка записи в реестр")
        return 1

    logging.info("Пауза продлена до %s", expiry)
    return 0


if __name__ == "__main__":
    sys.exit(main())