# 🌐 WhatsMyIP Mobile (Android)

Aplicación móvil Android rápida y minimalista desarrollada en **Flutter** para consultar y copiar la dirección IP pública directamente desde tu repositorio de GitHub al portapapeles sin interrumpir tu navegación actual.

---

## 🚀 ¿Qué hace WhatsMyIP?

1. **Overlay Translúcido (No sustituye la app actual):**
   - Configurada con ventana translúcida (`BackgroundMode.transparent` y `Theme.Translucent`).
   - Al pulsar el icono de la aplicación, el fondo simplemente se atenúa de forma suave, manteniendo visible la pantalla o aplicación en la que te encuentras.
2. **Copia instantánea al portapapeles:**
   - Consulta el archivo `IP.txt` en tu GitHub (`JulioGL98/current_IP`), extrae la IP pública y la copia automáticamente al portapapeles con vibración háptica de confirmación.
3. **Tarjeta flotante tipo notificación Android:**
   - Aparece en la parte superior con diseño Material 3 Dark.
   - Muestra la IP pública en tipografía monospace destacada.
   - Muestra la fecha de última actualización.
   - Botón **"Aceptar"** que cierra la aplicación de inmediato (`SystemNavigator.pop()`) devolviéndote a tu pantalla. También puedes tocar fuera de la tarjeta para cerrarla.
4. **Caché en 0 ms:**
   - Recuerda la última IP conocida para mostrarla instantáneamente sin tiempos de espera.

---

## 🛠️ Desarrollo Local (`dev.ps1`)

Para probar la app en tu emulador local con Hot Reload:
```powershell
.\dev.ps1
```

## 📦 Compilación de APK Release (`build_apk.ps1`)

Para compilar la versión release y copiarla a Descargas:
```powershell
.\build_apk.ps1
```
* **APK resultante:** `C:\Users\pepor\Downloads\WhatsMyIP_release.apk`
