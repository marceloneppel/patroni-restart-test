# Patroni Restart Test

This repository aims to show a difference on executing [patroni](https://github.com/zalando/patroni) on a situation where it's started by [pebble](https://github.com/canonical/pebble) and on another situation where it's started by [supervisord](http://supervisord.org).

The behavior that is shown here is related to killing the Patroni OS process and check whether each of the tools (pebble and supervisord) would correctly restart the process.

## Dependencies

The command below will install `curl`, `gettext-base` package (in order to use `envsubst`) and `microk8s` snap (you will also need Docker installed in your system).
```sh
make dependencies
```

Docker should be already installed in your system. Use a test environment to not mess with your microk8s or system.

## Building the images

Build the docker images (`test-pebble` and `test-supervisord`) using the following command:
```sh
make build
```

## Testing Patroni with Pebble starting it

Firstly you run the command to deploy the pods with pebble being the entrypoint. This time pebble starts patroni (we run `make clean` first in order to remove the previous deployment):

```sh
make clean
make pebble
```

Then, after the pod is deployed, you can login into the container with `microk8s kubectl exec -it patronidemo-0 -n pebble -- bash` and check the running processes:

```
root@patronidemo-0:/home/postgres# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0 926448 10328 ?        Ssl  01:25   0:00 /usr/bin/pebble run
postgres      18  0.8  0.2 489700 34648 ?        Sl   01:25   0:00 /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
postgres      47  0.0  0.1 215572 28052 ?        S    01:25   0:00 postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --li
postgres      50  0.0  0.0 215572  4304 ?        Ss   01:25   0:00 postgres: patronidemo: checkpointer   
postgres      51  0.0  0.0 215572  5772 ?        Ss   01:25   0:00 postgres: patronidemo: background writer   
postgres      52  0.0  0.0 215572 10004 ?        Ss   01:25   0:00 postgres: patronidemo: walwriter   
postgres      53  0.0  0.0 216128  6848 ?        Ss   01:25   0:00 postgres: patronidemo: autovacuum launcher   
postgres      54  0.0  0.0  69936  4928 ?        Ss   01:25   0:00 postgres: patronidemo: stats collector   
postgres      55  0.0  0.0 216024  6676 ?        Ss   01:25   0:00 postgres: patronidemo: logical replication launcher   
postgres      59  0.0  0.1 217756 18720 ?        Ss   01:25   0:00 postgres: patronidemo: postgres postgres 127.0.0.1(58156) idle
root          66  0.0  0.0   7244  3932 pts/0    Ss   01:25   0:00 bash
root          81  0.0  0.0   8896  3248 pts/0    R+   01:26   0:00 ps aux
```

The line with `/usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml` is the Patroni OS process.

You can then kill the OS process and check that it is removed from the process list.

```
root@patronidemo-0:/home/postgres# pkill --signal SIGKILL -f /usr/local/bin/patroni

root@patronidemo-0:/home/postgres# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0 926448 10328 ?        Ssl  01:25   0:00 /usr/bin/pebble run
postgres      47  0.0  0.1 215572 28052 ?        S    01:25   0:00 postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --li
postgres      50  0.0  0.0 215572  4304 ?        Ss   01:25   0:00 postgres: patronidemo: checkpointer   
postgres      51  0.0  0.0 215572  5772 ?        Ss   01:25   0:00 postgres: patronidemo: background writer   
postgres      52  0.0  0.0 215572 10004 ?        Ss   01:25   0:00 postgres: patronidemo: walwriter   
postgres      53  0.0  0.0 216128  6848 ?        Ss   01:25   0:00 postgres: patronidemo: autovacuum launcher   
postgres      54  0.0  0.0  69936  4928 ?        Ss   01:25   0:00 postgres: patronidemo: stats collector   
postgres      55  0.0  0.0 216024  6676 ?        Ss   01:25   0:00 postgres: patronidemo: logical replication launcher   
root          66  0.0  0.0   7244  3932 pts/0    Ss   01:25   0:00 bash
root          87  0.0  0.0   8896  3260 pts/0    R+   01:26   0:00 ps aux
```

But even with the `on-check-failure` section in the pebble layer, the service is not restarted.

```
root@patronidemo-0:/home/postgres# pebble services
Service  Startup  Current
patroni  enabled  inactive

root@patronidemo-0:/home/postgres# pebble checks
Check    Level  Status  Failures
patroni  -      down    4/3

root@patronidemo-0:/home/postgres# pebble changes
ID   Status  Spawn               Ready               Summary
1    Done    today at 01:25 UTC  today at 01:25 UTC  Autostart service "patroni"

root@patronidemo-0:/home/postgres# pebble tasks 1
Status  Spawn               Ready               Summary
Done    today at 01:25 UTC  today at 01:25 UTC  Start service "patroni"

root@patronidemo-0:/home/postgres# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0 926448 10328 ?        Ssl  01:25   0:00 /usr/bin/pebble run
postgres      47  0.0  0.1 215572 28052 ?        S    01:25   0:00 postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --li
postgres      50  0.0  0.0 215708  8176 ?        Ss   01:25   0:00 postgres: patronidemo: checkpointer   
postgres      51  0.0  0.0 215572  5772 ?        Ss   01:25   0:00 postgres: patronidemo: background writer   
postgres      52  0.0  0.0 215572 10004 ?        Ss   01:25   0:00 postgres: patronidemo: walwriter   
postgres      53  0.0  0.0 216128  8544 ?        Ss   01:25   0:00 postgres: patronidemo: autovacuum launcher   
postgres      54  0.0  0.0  69936  4928 ?        Ss   01:25   0:00 postgres: patronidemo: stats collector   
postgres      55  0.0  0.0 216024  6676 ?        Ss   01:25   0:00 postgres: patronidemo: logical replication launcher   
root          66  0.0  0.0   7244  3936 pts/0    Ss   01:25   0:00 bash
root         139  0.0  0.0   8896  3248 pts/0    R+   01:31   0:00 ps aux
```

Also, if we check the pod logs using `microk8s kubectl logs patronidemo-0 -n pebble` we get more and more errors (we also get the messages related to the process not existing):

```
2022-09-20T01:25:33.392Z [pebble] Started daemon.
2022-09-20T01:25:33.396Z [pebble] POST /v1/services 3.784058ms 202
2022-09-20T01:25:33.396Z [pebble] Started default services with change 1.
2022-09-20T01:25:33.400Z [pebble] Service "patroni" starting: /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
2022-09-20T01:26:33.393Z [pebble] Check "patroni" failure 1 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:26:43.393Z [pebble] Check "patroni" failure 2 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:26:53.393Z [pebble] Check "patroni" failure 3 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:26:53.393Z [pebble] Check "patroni" failure threshold 3 hit, triggering action
2022-09-20T01:26:53.393Z [pebble] Service "patroni" on-check-failure action is "restart", terminating process before restarting
2022-09-20T01:26:53.393Z [pebble] Cannot send SIGTERM to process: no such process
2022-09-20T01:26:58.394Z [pebble] Cannot send SIGKILL to process: no such process
2022-09-20T01:27:01.037Z [pebble] GET /v1/services?names= 134.38µs 200
2022-09-20T01:27:03.393Z [pebble] Check "patroni" failure 4 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:27:03.394Z [pebble] Service "patroni" still running after SIGTERM and SIGKILL
2022-09-20T01:27:06.262Z [pebble] GET /v1/checks 172.91µs 200
2022-09-20T01:27:11.650Z [pebble] GET /v1/changes?select=all 253.188µs 200
2022-09-20T01:27:13.393Z [pebble] Check "patroni" failure 5 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:27:23.393Z [pebble] Check "patroni" failure 6 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:27:29.564Z [pebble] GET /v1/logs?n=30 378.396µs 200
2022-09-20T01:27:33.393Z [pebble] Check "patroni" failure 7 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
2022-09-20T01:27:37.962Z [pebble] GET /v1/warnings 107.777µs 200
2022-09-20T01:27:43.393Z [pebble] Check "patroni" failure 8 (threshold 3): Get http://127.0.0.1:8008/health: dial tcp 127.0.0.1:8008: connect: connection refused
```

## Testing Patroni with Supervisord starting it

Firstly you run the command to deploy the pods with supervisord being the entrypoint. This time supervisord starts patroni (we run `make clean` first in order to remove the previous deployment):

```sh
make clean
make supervisord
```

Then, after the pod is deployed, you can login into the container with `microk8s kubectl exec -it patronidemo-0 -n supervisord -- bash` and check the running processes:

```
root@patronidemo-0:/home/postgres# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.1  31300 24020 ?        Ss   01:39   0:00 /usr/bin/python3 /usr/bin/supervisord
postgres       7  0.3  0.2 489700 34768 ?        Sl   01:39   0:00 /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
postgres      35  0.0  0.1 215572 28080 ?        S    01:39   0:00 postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --li
postgres      38  0.0  0.0 215572  4204 ?        Ss   01:39   0:00 postgres: patronidemo: checkpointer   
postgres      39  0.0  0.0 215572  5680 ?        Ss   01:39   0:00 postgres: patronidemo: background writer   
postgres      40  0.0  0.0 215572  9900 ?        Ss   01:39   0:00 postgres: patronidemo: walwriter   
postgres      41  0.0  0.0 216128  8392 ?        Ss   01:39   0:00 postgres: patronidemo: autovacuum launcher   
postgres      42  0.0  0.0  69936  4912 ?        Ss   01:39   0:00 postgres: patronidemo: stats collector   
postgres      43  0.0  0.0 216024  6636 ?        Ss   01:39   0:00 postgres: patronidemo: logical replication launcher   
postgres      47  0.0  0.1 217532 18572 ?        Ss   01:39   0:00 postgres: patronidemo: postgres postgres 127.0.0.1(44912) idle
root          61  0.3  0.0   7244  3928 pts/0    Ss   01:40   0:00 bash
root          70  0.0  0.0   8896  3344 pts/0    R+   01:40   0:00 ps aux
```

The line with `/usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml` is the Patroni OS process.

You can then kill the OS process and check that it is removed from the process list (and a new one was created - the restart process). Ignore the old PostgreSQL process in the process list.

```
root@patronidemo-0:/home/postgres# pkill --signal SIGKILL -f /usr/local/bin/patroni

root@patronidemo-0:/home/postgres# ps aux
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.1  0.1  31300 24036 ?        Ss   01:39   0:00 /usr/bin/python3 /usr/bin/supervisord
postgres      35  0.0  0.1 215572 28080 ?        S    01:39   0:00 postgres -D /home/postgres/pgdata/pgroot/data --config-file=/home/postgres/pgdata/pgroot/data/postgresql.conf --li
postgres      38  0.0  0.0 215572  4204 ?        Ss   01:39   0:00 postgres: patronidemo: checkpointer   
postgres      39  0.0  0.0 215572  5680 ?        Ss   01:39   0:00 postgres: patronidemo: background writer   
postgres      40  0.0  0.0 215572  9900 ?        Ss   01:39   0:00 postgres: patronidemo: walwriter   
postgres      41  0.0  0.0 216128  8392 ?        Ss   01:39   0:00 postgres: patronidemo: autovacuum launcher   
postgres      42  0.0  0.0  69936  4912 ?        Ss   01:39   0:00 postgres: patronidemo: stats collector   
postgres      43  0.0  0.0 216024  6636 ?        Ss   01:39   0:00 postgres: patronidemo: logical replication launcher   
root          61  0.0  0.0   7244  3928 pts/0    Ss   01:40   0:00 bash
postgres      79 19.0  0.2 415344 33524 ?        Sl   01:41   0:00 /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml
postgres      85  0.0  0.0 216800 14948 ?        Ss   01:41   0:00 postgres: patronidemo: postgres postgres 127.0.0.1(37688) idle
root          90  0.0  0.0   8896  3312 pts/0    R+   01:41   0:00 ps aux
```

Differently from pebble, supervisord correctly restarts the service after it was killed due to other reasons.

## Known issues

If you see a message like the one below when running `make pebble` or `make supervisord`, just run `make clean` and rerun the original command.

```
Warning: resource endpoints/patronidemo is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```

Also, we are using `host replication standby 0.0.0.0/0 md5` in the Postgres authentication rules just to make this example work the way we need. It's more secure to use the pod's IP.