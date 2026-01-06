# Guía de Plugins de Catime

## ¿Qué es un Plugin?

Un plugin es un archivo de script que muestra contenido personalizado en la ventana de Catime. Por ejemplo:

- 📺 Estadísticas de tus videos de Bilibili/YouTube
- 📈 Índices NASDAQ y S&P 500 en tiempo real
- 🌤️ Pronóstico del tiempo local
- 🌐 Estadísticas de tráfico de tu sitio web
- 💻 Estado del servidor
- ……

**Concepto central: ¡Cualquier dato que tu script pueda obtener puede mostrarse en la ventana de Catime!**

Además, estos datos pueden colocarse en cualquier lugar de tu pantalla y escalarse a cualquier tamaño, igual que la visualización de tiempo de Catime — siempre visible sin bloquear otras ventanas.

**Cómo funciona:** Tu script escribe en `output.txt` → Catime lo lee → Lo muestra en la ventana. ¡Así de simple!

> **Consejo:** Asegúrate de tener instalado el entorno de ejecución requerido (por ejemplo, Python, Node.js, etc.)

---

## Inicio Rápido en 30 Segundos

¿No quieres escribir código? Pruébalo manualmente primero:

### Paso 1: Abrir Carpeta de Plugins

Clic derecho en el icono de Catime → `Plugins` → `Abrir Carpeta de Plugins`

### Paso 2: Editar output.txt

Encuentra (o crea) `output.txt` en la carpeta y escribe algo:

```
¡Hola, Catime!
Este es mi primer mensaje 🎉
```

### Paso 3: Mostrar Contenido del Archivo

Clic derecho en el icono de Catime → `Plugins` → `Mostrar Archivo de Plugin`

**¡Listo!** La ventana de Catime ahora muestra tu contenido.

> Esta es la esencia de los plugins: **Lo que escribas en output.txt aparece en la ventana**.
> Los scripts de plugins solo automatizan este proceso.

---

## Crea Tu Primer Plugin en 3 Pasos

### Paso 1: Abrir Carpeta de Plugins

Clic derecho en el icono de Catime → `Plugins` → `Abrir Carpeta de Plugins`

### Paso 2: Crear Archivo de Script

Crea un nuevo archivo en esta carpeta, por ejemplo, `hello.py`:

```python
with open('output.txt', 'w', encoding='utf-8') as f:
    f.write('¡Hola, Catime!')
```

**¡Solo unas pocas líneas!**

### Paso 3: Ejecutar Plugin

1. Clic derecho en el icono de Catime
2. `Plugins` → Clic en `hello.py`
3. La primera vez preguntará si confías, haz clic en "Confiar y Ejecutar"

**¡Listo!** La ventana ahora muestra "¡Hola, Catime!"

---

## Punto Clave

Lo que tu script escriba en `output.txt`, Catime lo muestra. La visualización se actualiza automáticamente cuando el archivo se actualiza.

---

## Etiquetas Especiales (Opcional)

Usa estas etiquetas si las necesitas:

| Etiqueta | Función | Ejemplo |
|----------|---------|---------|
| `<md></md>` | Habilitar formato Markdown | `<md>**negrita** *cursiva*</md>` |
| `<catime></catime>` | Mostrar tiempo del temporizador | `Ejecutando <catime></catime>` → `Ejecutando 00:05:30` |
| `<exit>N</exit>` | Cerrar plugin automáticamente después de N segundos | `<exit>5</exit>` → cierra después de 5 segundos |
| `<fps:N>` | Actualizar N veces por segundo (predeterminado 2, rango 1-100) | `<fps:10>` → 10 actualizaciones por segundo |
| `<color:valor></color>` | Establecer color de texto (soporta degradados) | `<color:#FF0000>rojo</color>` |
| `<font:ruta></font>` | Establecer fuente (ruta del archivo de fuente) | `<font:C:\Windows\Fonts\comic.ttf>divertido</font>` |
| `![](ruta)` | Mostrar imagen (ruta local o URL) | `![](clima.png)` o `![](https://example.com/img.png)` |
| `![AxA](ruta)` | Mostrar imagen con tamaño específico | `![100x50](logo.png)` o `![200](logo.png)` (solo ancho) |

> **Sobre `<fps:N>`:** La actualización predeterminada es cada 500ms (2 veces por segundo). Para datos que se actualizan rápidamente, aumenta la tasa hasta `<fps:100>` (100 veces por segundo).

> **Sobre color y fuente:** Estas etiquetas funcionan independientemente (no necesitan `<md>`) y pueden anidarse. Las rutas de fuentes soportan rutas absolutas, variables de entorno o rutas relativas al directorio del plugin.

---

## Lenguajes Soportados

Python, PowerShell, Batch, JavaScript... incluso Shell, Ruby, PHP, Lua y **más de 90 lenguajes** son soportados. Mientras tengas el intérprete instalado, cualquier lenguaje funciona.

> **Recomendado:** Usa **PowerShell (.ps1)** o **Batch (.bat)** — integrados en Windows, sin instalación necesaria, menor uso de recursos.

---

## ¿Es Seguro?

Al ejecutar un plugin por primera vez, Catime preguntará:

- **Cancelar** = No ejecutar
- **Ejecutar Una Vez** = Ejecutar solo esta vez, preguntará de nuevo la próxima vez
- **Confiar y Ejecutar** = Siempre ejecutar automáticamente

Si modificas un archivo de plugin, Catime preguntará de nuevo para prevenir manipulación.

---

## Preguntas Frecuentes

### ¿El plugin no muestra contenido?

Verifica:
- La ruta del archivo es correcta (el script debe escribir en `output.txt` en el mismo directorio)
- El intérprete está instalado (por ejemplo, scripts de Python necesitan Python instalado)

### ¿Cómo detener un plugin?

Clic derecho en el icono → Plugins → Clic de nuevo en el plugin en ejecución (marcado con ✓)

### ¿Necesito reiniciar después de editar?

¡No! Catime detecta cambios automáticamente y vuelve a ejecutar el plugin (recarga en caliente).

### ¿Puedo ejecutar múltiples plugins?

No, solo uno a la vez. Haz clic en otro plugin para cambiar; el actual se detiene automáticamente.

### ¿Los plugins siguen ejecutándose después de cerrar Catime?

No. Catime detiene todos los procesos de plugins cuando se cierra.

---

## Notas

⚠️ **Evita subprocesos anidados**

Usa un solo proceso para completar tareas. Si tu script genera subprocesos (por ejemplo, usando `start` en `.bat`), pueden no limpiarse correctamente.

---

**¡Eso es todo! ¡Ahora ve a crear tu primer plugin!** 🚀
