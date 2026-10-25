# WhatsApp Bar

Widget para la barra de [Omarchy](https://omarchy.org/) que oculta y muestra la ventana de WhatsApp Web con un clic y muestra cuántas conversaciones te han escrito desde la última vez que la miraste.

![WhatsApp Bar](preview.png)

## Características

- Un clic oculta la ventana de WhatsApp; otro la trae de vuelta al workspace en el que estés y le da el foco
- **Nunca oculta las ventanas de llamada o videollamada**, aunque estés en mitad de una
- Muestra junto al logo, en el gris de la barra, el número de conversaciones con mensajes nuevos
- Solo aparece mientras WhatsApp está abierto
- Se actualiza con los eventos de Hyprland y de las notificaciones, sin consultas periódicas

## Instalación

```bash
omarchy plugin add https://github.com/Elipserus/WhatsAppBar --enable
```

Se coloca en la zona central de la barra. Para ponerlo justo detrás del tiempo:

```bash
omarchy bar move io.github.elipserus.whatsapp --after omarchy.weather
```

## Desinstalación

```bash
omarchy plugin remove io.github.elipserus.whatsapp
```

## Uso

Haz clic en el logo de WhatsApp para ocultar su ventana y vuelve a hacer clic para mostrarla. Al pasar el ratón, el tooltip indica la acción y cuántas conversaciones tienes pendientes.

### Atajos de teclado y scripts

El widget expone un destino IPC, así que puedes asignar estas órdenes a teclas en `~/.config/hypr/bindings.lua`:

```bash
omarchy-shell io.github.elipserus.whatsapp toggle    # ocultar o mostrar
omarchy-shell io.github.elipserus.whatsapp clear     # poner el contador a cero
omarchy-shell io.github.elipserus.whatsapp refresh   # releer el estado de la ventana
```

El script incluido también funciona por sí solo:

```bash
./whatsapp-toggle status   # muestra "<abierto> <oculto> <dirección>", p. ej. "1 0 0x5640..."
./whatsapp-toggle hide     # oculta
./whatsapp-toggle show     # muestra
./whatsapp-toggle toggle   # alterna
./whatsapp-toggle watch    # muestra cada notificación nueva de WhatsApp
```

## Cómo funciona

**Ocultar y mostrar.** WhatsApp Web se ejecuta como web app del navegador (Omarchy la abre con `omarchy-launch-webapp`), con una clase de ventana como `brave-web.whatsapp.com__-Default`. Las llamadas se abren en otra ventana de la misma clase, con el título "Llamada de WhatsApp", así que el script deja fuera cualquier ventana cuyo título contenga "llamada" o "call". Para ocultarla, la ventana se mueve al workspace especial `special:whatsapp`; para mostrarla, vuelve al workspace activo.

**Contador.** WhatsApp Web no publica su número de mensajes sin leer en ningún sitio accesible: ni siquiera cambia el título de su ventana. Por eso el widget cuenta sus **notificaciones**. Omarchy no deja a los plugins de terceros acceder a su servicio de notificaciones, pero guarda cada notificación como fichero en `~/.local/state/omarchy/notifications/`; el script vigila esa carpeta con `inotifywait` y reconoce las de WhatsApp porque su texto empieza por `web.whatsapp.com`. Cada chat distinto suma uno, y el contador vuelve a cero cuando miras la ventana de WhatsApp.

### Limitaciones del contador

Como se basa en las notificaciones, no es el recuento exacto de WhatsApp:

- No cuenta los mensajes que llegaron antes de arrancar el widget (por ejemplo, al reiniciar el shell)
- No cuenta los chats silenciados ni los mensajes que llegan con "No molestar" activo
- No se pone a cero si lees los mensajes en el móvil; solo al mirar la ventana de WhatsApp o con la orden `clear`
- Necesita que las notificaciones de WhatsApp Web estén activadas en el navegador

## Requisitos

- Omarchy con el shell basado en Quickshell y la configuración de Hyprland en Lua
- WhatsApp Web abierto como web app de Omarchy
- `jq` e `inotify-tools`

## Créditos

Logo de WhatsApp de [Simple Icons](https://simpleicons.org/) (CC0). WhatsApp es una marca de WhatsApp LLC; este proyecto no está afiliado a WhatsApp ni a Meta.

## Licencia

MIT
