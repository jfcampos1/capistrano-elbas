# Changelog

Fork de [lserman/capistrano-elbas](https://github.com/lserman/capistrano-elbas) a partir de `17ec664` (versión 3.0.4, varios Auto Scaling Groups y launch templates). La versión de la gema sigue en 3.0.4. Cada entrada es un cambio de este fork, de la rama más nueva a la más vieja.

## ssh-host-instance-id — 2026-10-26

`2ff9793`, encima de `update-launch-template-version`.

El host con el que Capistrano se conecta se elige con `elbas_server_host`. El mismo valor se usa al hornear la AMI, así que la imagen sale de una instancia que recibió el deploy.

- `:public_dns` es el default y conserva el comportamiento anterior (`public_dns_name`).
- `:public_ip` registra la IP pública.
- `:instance_id` registra el `i-…`, que es el target de SSH sobre SSM Session Manager.
- Un host vacío o un valor distinto de esos tres corta el deploy con `ArgumentError`.
- `cap <stage> elbas:ssh` imprime `ssh user@host` para DNS e IP. Con `:instance_id` imprime el mismo `ssh` más el `ProxyCommand` de `AWS-StartSSHSession`.
- El túnel no lo abre la gema. Hay que pasar el `ProxyCommand` en `ssh_options` para que `%h` sea la instance id.

## update-launch-template-version — 2022-12-22

`35ea8f9`, encima de `master`.

Después de crear una versión nueva del launch template, elbas llama a `modify_launch_template` y la deja como `default_version`. Si esa llamada no responde con éxito, no sigue con el resto del deploy de la AMI.

Antes, elbas creaba la versión y el Auto Scaling Group podía seguir lanzando instancias con la versión default anterior.

## master — 2022-12-20

`c962fed`, integrado en `fa69959`.

La AMI se crea a partir de una instancia que participó en el deploy en curso. elbas compara el hostname de cada instancia del grupo con los servers que Capistrano registró. Si el grupo no tiene ninguna de esas instancias, escribe `skip AMI creation` y pasa al siguiente grupo.

Antes, elbas tomaba cualquier instancia en ejecución del grupo, aunque ese deploy no hubiera llegado hasta ella.
