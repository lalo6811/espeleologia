# Espeleología — La Cueva Real (Godot 4)

Proyecto **completo y jugable** en Godot 4.2+ del juego de espeleología,
reconstruido como una **cueva real, no como un juego de plataformas**:
no hay plataformas flotantes ni saltos entre repisas. El mundo es roca
sólida con un vacío continuo tallado dentro.

## Cómo abrirlo

1. Descomprime el ZIP.
2. Abre **Godot 4.2 o superior** → *Importar* → elige `project.godot`.
3. Pulsa **▶ Ejecutar proyecto** (F5).

No necesitas descargar assets: todo el arte es **vectorial procedural**
generado por código (sin pixel art), así que el proyecto corre tal cual.

## La cueva (de superficie a fondo)

| Zona | Qué pasa ahí |
|---|---|
| Campamento base (superficie) | Tienda con **T**, fogata, venta automática del botín al volver |
| Galería de entrada | Túnel ancho que desciende, primeros cristales |
| **Paso bajo** | Techo a ~46 px: solo se cruza **arrastrándose** (automático, o con ↓/S) |
| **Pendiente escalable** | Subida/bajada inclinada: se escala despacio, con agarres y gasto de energía |
| **Sala Grande** | Cámara enorme con columnas, resplandor púrpura, campamento para descansar |
| **Pozo vertical** | Descenso con **cuerda flexible (Verlet, tipo Limbo)**: **E** para agarrarla, **W/S** rappel, **A/D** balanceo para impulsarte |
| Galería inferior | Fósiles y cristales más valiosos |
| **Río y sifón** | Agua profunda: se **nada y bucea** (W/S), con **medidor de aire** y burbujas |
| Sala de Cristales | La zona más profunda y valiosa |

## El personaje: un humano, no un robot

El espeleólogo se dibuja por código en `scripts/jugador.gd` como silueta
vectorial con volumen, igual que en tus imágenes de referencia (explorador
en silueta oscura, casco con frontal encendida, mochila con petate, cuerda
enrollada y piolet):

- Piernas y brazos con **IK de dos huesos**: muslo/pantorrilla y
  brazo/antebrazo con rodilla y codo reales — nada de extremidades de palo.
- Cabeza de perfil con frente, nariz y mentón; casco con correa; guantes,
  botas, cinturón y cierre de chaqueta; **borde de luz cálida** del lado
  de su propia lámpara.
- Poses y ciclos distintos para caminar, correr, **arrastrarse, nadar con
  brazadas y patada, escalar pendientes y hacer rappel**.

> Nota honesta: es un personaje 2D vectorial procedural, el máximo realismo
> posible sin assets externos. Si luego quieres más, el siguiente paso es
> sustituir el dibujo de `jugador.gd` por un esqueleto `Skeleton2D` con un
> sprite pintado, sin tocar el resto del juego.

## Sistema de luz (como en tu imagen)

- `CanvasModulate` azul/púrpura profundo: fuera de las luces, la cueva
  **no se ve negra, se ve azul oscuro en capas**, como en la referencia.
- La luz del jugador es un **cono cálido** (`PointLight2D` con textura de
  cono generada por código) que sale de la linterna o de la frontal del
  casco, sigue su dirección y su postura (bajo al arrastrarse, recto al
  nadar, hacia abajo en rappel). **Parpadea y se corta** con la batería
  casi vacía, y se apaga en 0.
- Brillos propios: **hongos cian** que pulsan, **cristales púrpura**,
  fogatas naranjas que titilan, resplandor de la boca y de la Sala Grande.

## Sistemas completos

- **Supervivencia:** hambre, energía, batería y aire (bajo el agua).
  Raciones con **F**, cambio de batería con **R**, luz con **L**.
- **Economía:** recoge cristales y fósiles → véndelos al volver a la
  superficie → compra en la tienda (**T**): linterna, frontal de casco,
  mochila grande, piolet, baterías, raciones y kits de campamento.
- **Campamentos:** los montados (Sala Grande y Sala de Cristales) dejan
  descansar y **guardar el botín a salvo** con **E**. Con un kit puedes
  montar el tuyo con **C** en suelo plano con techo alto.
- **HUD como la referencia:** iconos arriba a la izquierda y **minimapa
  circular abajo a la derecha** con el perfil de la cueva, campamentos
  y `Profundidad: XXXm`.
- **Sin enemigos**, como pediste.

## Controles

| Tecla | Acción |
|---|---|
| A/D o ←/→ | Moverse |
| Shift | Correr |
| Espacio | Saltar (solo un brinco corto, no es un plataformas) |
| ↓ / S | Agacharse / arrastrarse / bajar en el agua o la cuerda |
| W / ↑ | Subir en el agua o por la cuerda |
| E | Interactuar: cuerda del pozo, campamentos |
| C | Montar campamento (con kit, suelo plano) |
| L | Encender / apagar la luz |
| F | Comer una ración |
| R | Cambiar batería |
| T | Tienda (solo en el campamento base) |
| Esc | Cerrar tienda |

## Estructura

```
project.godot            Configuración Godot 4 (escena principal)
escenas/main.tscn        Escena principal (todo se construye por código)
scripts/
  juego.gd               Mundo, colisión de la roca, luces, botín, economía
  jugador.gd             Movimiento, modos, supervivencia y DIBUJO del humano
  cueva_datos.gd         Perfil real de la cueva: suelo/techo continuos, zonas
  cueva_dibujo.gd        Roca, estratos, estalactitas, columnas, agua, tiendas
  cuerda.gd              Cuerda flexible Verlet (se curva y se tensa sola)
  botin.gd               Cristales y fósiles con luz propia
  hud.gd                 Barras, mensajes y tienda
  minimapa.gd            Minimapa circular con profundidad
export_presets.cfg       Presets de exportación: Windows y Web
```

## Para seguir creciendo

- **Editar la cueva:** cambia los puntos de `SUELO` y `ALTURA` en
  `cueva_datos.gd`; colisión, dibujo, minimapa y zonas se ajustan solos.
- **Exportar:** *Proyecto → Exportar* (presets Windows y Web incluidos;
  la primera vez Godot te pedirá instalar las plantillas de exportación).
- **Guardar partida:** el progreso vive mientras juegas; el siguiente
  paso natural es guardarlo con `FileAccess` en `user://partida.save`.
