# GTFOLenam


<img src="image.png" width="500" alt="GTFOLenam scanner" style="margin-left:auto;margin-right:auto">

```bash
./gtfolenam.sh [-v] [-h] [-t=sudo,capabilities,...]
```

Herramienta de uso personal para la enumeración de posibles vectores para la elevación de privilegios en CTFs y sistemas con S.O. Linux.

Se escanean los binarios del sistema `sudo`, `suid` o con `capabilities` y se comprueba si existen en la web de [GTFOBins](https://gtfobins.github.io/). Si el binario existe, se muestra un enlace a la información.

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

En una carpeta con permisos de escritura.

```
wget https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

### Dependencias

Utiliza `curl` o `wget`, lo que esté en el sistema, para realizar la petición a [GTFOBins](https://gtfobins.github.io/), y usa `grep` y `awk` para filtrar el resultado.

```
$ sudo apt install curl grep gawk
``` 

## Futuras ideas
- [x] Filtrar binarios conocidos para eliminar las peticiones innecesarias a GTFOBins.
- [x] Quitar la dependencia de `pup`.
- [x] Comprobar si existe el binario `curl` o `wget` para realizar la petición.
- [ ] Comprobar si existe el binario `grep` o `awk` para filtrar la petición.
- [ ] Parámetro para mostrar los binarios aunque no estén en GTFOBins.
- [ ] Parámetro para la ejecución directa de los ejemplos.
- [ ] Parámetro para mostrar el usuario al que se le adquieren los privilegios.
- [ ] Comprobar también los binarios dentro de `doas`, actualmente no están en GTFOBins.

## Advertencia Legal

Este software está diseñado únicamente para uso personal y debe emplearse exclusivamente en entornos controlados y autorizados. El uso de esta herramienta en sistemas o redes sin la debida autorización puede ser ilegal y violar políticas de seguridad. El desarrollador no asume ninguna responsabilidad por daños, pérdidas o consecuencias derivadas de su uso indebido o no autorizado. Asegúrate de cumplir con todas las leyes y regulaciones locales aplicables antes de utilizar esta herramienta.