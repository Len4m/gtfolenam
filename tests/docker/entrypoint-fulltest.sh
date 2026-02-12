#!/bin/sh
# setcap en runtime: overlay2 no soporta xattr; tmpfs sí. Requiere root para setcap.
# Requiere: docker run --tmpfs /cap-test:mode=0755 (sin --user; entrypoint corre como root)
cp /usr/local/bin/python /cap-test/python
setcap cap_setuid+ep /cap-test/python
# Tests deben ejecutarse como auditor (sudo test)
exec runuser -u auditor -- "$@"
