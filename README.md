# gtfolenam.sh

```bash
./gtfolenam.sh [-v] [-h] [-t=sudo,capabilities,...]
```

Herramienta de uso personal para la enumeración de posibles vectores para la elevación de privilegios en CTFs y sistemas con S.O. Linux.

Se escanean los binarios del sistema `sudo`, `suid` o con `capabilities` y se comprueba si existen en la web de [GTFOBins](https://gtfobins.github.io/). Si el binario existe, se muestra un enlace a la información.

Ayuda
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

**Atención**: Esta herramienta es de uso personal y para ser utilizada exclusivamente en entornos controlados. No nos hacemos responsables del mal uso o funcionamiento de la misma.

## Dependencias

El script utiliza la herramienta `pup` de forma temporal. Esta se encuentra en los repositorios oficiales de debian.

```
$ sudo apt install pup
``` 

## Futuras ideas:
- [ ] Filtrar binarios conocidos para eliminar las peticiones innecesarias a GTFOBins.
- [ ] Quitar la dependencia de `pup`.
- [ ] Comprobar también los binarios dentro de `doas`.
- [ ] Parámetro para mostrar los binarios aunque no estén en GTFOBins.
- [ ] Parámetro para la ejecución directa de los ejemplos
