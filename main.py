import sys
import winreg
from datetime import datetime, timedelta, timezone

def is_admin():
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if not is_admin():
    print("Запустите скрипт от имени Администратора!")
    sys.exit()

# Настройки времени
now = datetime.now(timezone.utc)
start_time = now.strftime("%Y-%m-%dT%H:%M:%SZ")
expiry_time = (now + timedelta(days=7)).strftime("%Y-%m-%dT%H:%M:%SZ")

registry_path = r"SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"

try:
    key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, registry_path, 0, winreg.KEY_SET_VALUE)

    winreg.SetValueEx(key, "PauseUpdatesStartTime", 0, winreg.REG_SZ, start_time)
    winreg.SetValueEx(key, "PauseUpdatesExpiryTime", 0, winreg.REG_SZ, expiry_time)
    winreg.SetValueEx(key, "PauseFeatureUpdatesStartTime", 0, winreg.REG_SZ, start_time)
    winreg.SetValueEx(key, "PauseQualityUpdatesStartTime", 0, winreg.REG_SZ, start_time)

    winreg.CloseKey(key)
    print(f"Готово. Пауза обновлений сдвинута до {expiry_time}")
except Exception as e:
    print(f"Ошибка записи в реестр: {e}")