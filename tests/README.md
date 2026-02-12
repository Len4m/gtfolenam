# Tests de GTFOLenam

**Todos los tests dentro de contenedores Docker.**

```bash
./tests/run_all.sh
```

## Contenedores (3)

| Imagen | Propósito |
|--------|-----------|
| gtfolenam-testrunner | Ayuda, sintaxis, banner, verbose, opciones -t, escaneo completo |
| gtfolenam-fulltest | Sudo + SUID + capabilities (binarios vulnerables reales) |
| gtfolenam-busybox | Fallback a busybox; detecta find SUID |

## Tests (10)

| Contenedor | Test | Qué verifica |
|------------|------|--------------|
| testrunner | 01 | Ayuda -h completa |
| testrunner | 02 | Sintaxis bash correcta |
| testrunner | 03 | Banner y versión |
| testrunner | 04 | Modo verbose -v |
| testrunner | 05 | Opciones -t (combo, único, tipo inválido) |
| testrunner | 06 | Escaneo completo sin crashear |
| fulltest | 01 | Detecta find en sudo NOPASSWD |
| fulltest | 02 | Detecta find SUID vulnerable |
| fulltest | 03 | Detecta python con capabilities (tmpfs + setcap) |
| busybox | 01 | Funciona con busybox; detecta find SUID |
