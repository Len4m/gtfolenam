![GitHub License](https://img.shields.io/github/license/len4m/gtfolenam?style=flat-square)
[![es](https://img.shields.io/badge/README-es-red.svg?style=flat-square)](https://github.com/len4m/gtfolenam/)
[![en](https://img.shields.io/badge/README-en-yellow.svg?style=flat-square)](https://github.com/Len4m/gtfolenam/blob/main/README.en.md)

# GTFOLenam v2.0

<img src="image.png" width="500" alt="GTFOLenam scanner" style="margin-left:auto;margin-right:auto">

```bash
./gtfolenam.sh [-v] [-h] [-t=sudo,suid,capabilities] [-u]
```

**Qué hace**: Escanea binarios con `sudo`, `SUID` o `capabilities` y los compara con [GTFOBins](https://gtfobins.org/). Si el binario es explotable, muestra el enlace a la técnica. Pensado para CTFs y auditorías Linux.

**Funcionamiento**: La base de datos de GTFOBins va embebida en el script. Ejecuta `./gtfolenam.sh -u` en tu máquina (con internet) para actualizarla; el script **se modifica a sí mismo** con los nuevos datos. Después transfiere el script al objetivo y escanea sin red.

> El script ha sido prácticamente reprogramado por completo debido a la actualización de la web de GTFOBins.

## Características

- **Offline**: a diferencia del script anterior, el escaneo no requiere conexión a internet
- **Autoactualizable**: `-u` descarga la última BD y la incrusta en el script
- **Dependencias mínimas**: awk, sed (y grep solo si usas sudo)
- **Sudo**: indica si cada comando requiere contraseña (NOPASSWD) o no

## Ayuda

```
$ ./gtfolenam.sh -h
Uso: ./gtfolenam.sh [-v] [-h] [-t=tipo1,tipo2,...] [-u]

Opciones:
  -v    Modo verbose.
  -h    Muestra esta ayuda.
  -t    Tipos: sudo, suid, capabilities (por defecto: todos)
  -u    Actualiza los datos GTFOBins embebidos desde gtfobins.org/api.json

Los datos de GTFOBins están embebidos para uso offline.
```

## Dependencias

Para el **escaneo**, el script busca alternativas (busybox, rutas habituales) cuando una herramienta no está en el PATH, evitando instalar dependencias; tampoco requiere conexión a internet. Con **-u** (actualización) también usa busybox para curl/wget y sed, pero **jq o python3** son obligatorios (sin alternativa) para parsear el JSON, además de conexión a internet.

| Uso | Herramientas |
|-----|--------------|
| **Escaneo** | awk, sed, find, getcap (grep solo si usas sudo) |
| **Actualización (-u)** | curl o wget, jq o python3, conexión a internet |

## Instalación

**Con wget:**

```bash
wget https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**Con curl:**

```bash
curl -O https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**Con busybox wget:**

```bash
busybox wget -O gtfolenam.sh https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**Con busybox curl:**

```bash
busybox curl -o gtfolenam.sh https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**Sin herramientas de descarga:** transfiere el script por SCP, SFTP, netcat, etc. y luego ejecuta:

```bash
chmod +x gtfolenam.sh
```

## Ejemplos

**Actualizar BD embebida** (mejor en tu máquina, luego transfiere):

```bash
./gtfolenam.sh -u
```

**Escaneo completo:**

```bash
./gtfolenam.sh
```

**Solo SUID:**

```bash
./gtfolenam.sh -t suid
```

**Sudo + capabilities:**

```bash
./gtfolenam.sh -t=sudo,capabilities
```

**Verbose** (muestra todos los binarios; no vulnerables en verde):

```bash
./gtfolenam.sh -v
```

## Binarios excluidos

Se filtran SUID/capabilities legítimos que no son explotables en GTFOBins: passwd, sudo, su, chsh, chfn, gpasswd, newgrp, fusermount, mount, umount, ssh-keysign, ping, ping6, etc.

## Advertencia legal

Esta herramienta se proporciona "tal cual", sin garantía de ningún tipo. Está destinada exclusivamente a:
- **Uso legítimo** en sistemas propios o sobre los que tengas autorización explícita por escrito
- **CTFs** y entornos de práctica autorizados
- **Auditorías de seguridad** bajo contrato o permiso del titular del sistema

**Prohibido**: el acceso no autorizado a sistemas informáticos constituye delito en la mayoría de jurisdicciones. El usuario es el único responsable de asegurarse de tener los permisos necesarios antes de ejecutar este script.

El autor **no asume ninguna responsabilidad** por daños, consecuencias legales, pérdidas o perjuicios derivados del uso indebido, ilegal o no autorizado de esta herramienta. El uso queda bajo la exclusiva responsabilidad del usuario.
