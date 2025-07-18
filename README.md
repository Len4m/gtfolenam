![GitHub License](https://img.shields.io/github/license/len4m/gtfolenam?style=flat-square)
[![es](https://img.shields.io/badge/README-es-red.svg?style=flat-square)](https://github.com/len4m/gtfolenam/)
[![en](https://img.shields.io/badge/README-en-yellow.svg?style=flat-square)](https://github.com/Len4m/gtfolenam/blob/main/README.en.md)

# GTFOLenam

<img src="image.png" width="500" alt="GTFOLenam scanner" style="margin-left:auto;margin-right:auto">

```bash
./gtfolenam.sh [-v] [-h] [-t=sudo,capabilities,...]
```

Herramienta de uso personal para la enumeración de posibles vectores para la elevación de privilegios en CTFs y sistemas con S.O. Linux.

Se escanean los binarios del sistema `sudo`, `suid` o con `capabilities` y se comprueba si existen en la web de [GTFOBins](https://gtfobins.github.io/). Si el binario existe, se muestra un enlace a la información.

**Diseñado para funcionar en entornos donde no se pueden instalar dependencias adicionales**, detectando automáticamente las herramientas disponibles en el sistema.

## Ayuda

```
$ ./gtfolenam.sh -h
Uso: ./gtfolenam.sh [-v] [-h] [-t=tipo1,tipo2,...]

Opciones:
  -v    Modo verbose. Muestra información detallada del proceso y todos los archivos, incluso si fallan la evaluación.
  -h    Muestra esta ayuda y termina.
  -t    Tipo de escaneo a realizar, separado por comas, precedido por '='.
        Opciones válidas: sudo, suid, capabilities.
        Por defecto, se escanean todos los tipos si no se especifica.
```
## Instalación

En una carpeta con permisos de escritura. El script está diseñado para funcionar sin instalar dependencias adicionales.

### Con wget (recomendado)
```bash
wget https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

### Con curl
```bash
curl -O https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

### Con busybox wget
```bash
busybox wget https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

### Con busybox curl
```bash
busybox curl -O https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

### Sin herramientas de descarga
Si no tienes ninguna herramienta de descarga disponible, necesitarás transferir el script desde otro sistema usando métodos como:
- **SCP/SFTP**: `scp gtfolenam.sh usuario@servidor:/ruta/destino/`
- **Copia directa**: Si tienes acceso físico o por consola, copia el contenido del script
- **Transferencia por red**: Usando `nc` (netcat) u otras herramientas de red disponibles

Una vez transferido, ejecuta:
```bash
chmod +x gtfolenam.sh
```

### Dependencias

El script requiere las siguientes herramientas para funcionar:
- **Descarga web**: `curl` o `wget` (o `busybox` con estas funciones integradas)
- **Procesamiento de texto**: `grep` y `awk` (o `busybox` con estas funciones integradas)

**Nota**: El script detectará automáticamente qué herramientas están disponibles en el sistema y las utilizará. No es necesario instalar dependencias adicionales.

> 💡 **Para sistemas donde puedes instalar paquetes** (opcional):
> ```bash
> $ sudo apt install curl grep gawk
> ``` 

## Futuras ideas
- [x] Filtrar binarios conocidos para eliminar las peticiones innecesarias a GTFOBins.
- [x] Quitar la dependencia de `pup`.
- [x] Comprobar si existe el binario `curl` o `wget` para realizar la petición.
- [x] Comprobar si existe el binario `grep` o `awk` para filtrar la petición.
- [x] Soporte para `busybox` con `wget`, `curl`, `grep` o `awk` integrados para sistemas embedded.
- [x] Parámetro para mostrar los binarios aunque no estén en GTFOBins (flag `-v`).
- [ ] Parámetro para la ejecución directa de los ejemplos.
- [ ] Parámetro para mostrar el usuario al que se le adquieren los privilegios.
- [ ] Comprobar también los binarios dentro de `doas`, actualmente no están en GTFOBins.

## Advertencia Legal

Este software está diseñado únicamente para uso personal y debe emplearse exclusivamente en entornos controlados y autorizados. El uso de esta herramienta en sistemas o redes sin la debida autorización puede ser ilegal y violar políticas de seguridad. El desarrollador no asume ninguna responsabilidad por daños, pérdidas o consecuencias derivadas de su uso indebido o no autorizado. Asegúrate de cumplir con todas las leyes y regulaciones locales aplicables antes de utilizar esta herramienta.