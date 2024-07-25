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

Utiliza `curl` para realizar la petición a [GTFOBins](https://gtfobins.github.io/) y `grep` para filtrar el resultado.

```
$ sudo apt install curl grep
``` 

## Futuras ideas:
- [x] Filtrar binarios conocidos para eliminar las peticiones innecesarias a GTFOBins.
- [x] Quitar la dependencia de `pup`.
- [ ] Comprobar si existe el binario `curl` o `wget` para realizar la petición.
- [ ] Comprobar si existe el binario `grep` o `awk` para filtrar la petición.
- [ ] Comprobar también los binarios dentro de `doas`.
- [ ] Parámetro para mostrar los binarios aunque no estén en GTFOBins.
- [ ] Parámetro para la ejecución directa de los ejemplos
