# Custom Cron task / Scheduled Jobs

Since the container runs as a non-root user (`www-data`), traditional cron is not available.  
Instead, you can add custom supervisor-managed jobs by mounting configuration files into `/etc/supervisor/conf.d/`.

## Quick Start

1. Create a supervisor config file for your job
2. Mount it into the container at `/etc/supervisor/conf.d/your-job.conf`

## Using the Built-in Scheduler

The image includes a flexible scheduler script at `/opt/glpi/scheduler.sh` that supports two scheduling modes:

### Interval Mode

Runs the command immediately on start, then repeats every N seconds:

```bash
/opt/glpi/scheduler.sh --interval 21600 -- php bin/console ldap:synchronize_users
```

### Daily Mode

Waits until the specified time, then repeats daily:

```bash
/opt/glpi/scheduler.sh --daily 03:00 -- php bin/console ldap:synchronize_users
```

### Options

| Option                 | Description                           |
|------------------------|---------------------------------------|
| `--interval <seconds>` | Run immediately, then every N seconds |
| `--daily <HH:MM>`      | Wait until time, then repeat daily    |
| `--name <name>`        | Name to display in logs (optional)    |
| `--no-wait-for-db`     | Skip database availability check      |

## Example: LDAP Sync Every 6 Hours

Create `ldap-sync.conf`:

```ini
[program:ldap-sync]
command = /opt/glpi/scheduler.sh --interval 21600 --name "LDAP Sync" -- php /var/www/glpi/bin/console ldap:synchronize_users
autorestart = true
stdout_logfile = /dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile = /dev/stderr
stderr_logfile_maxbytes = 0
```

Mount in docker-compose.yml:

```yaml
services:
  glpi:
    image: glpi/glpi
    volumes:
      - ./ldap-sync.conf:/etc/supervisor/conf.d/ldap-sync.conf:ro
```

## Example: Daily Backup at 2 AM

Create `backup.conf`:

```ini
[program:daily-backup]
command = /opt/glpi/scheduler.sh --daily 02:00 --name "Daily Backup" -- /opt/glpi/scripts/backup.sh
autorestart = true
stdout_logfile = /dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile = /dev/stderr
stderr_logfile_maxbytes = 0
```

## Example: Custom Script Without Scheduler

For complex scheduling needs, you can write your own script:

Create `my-custom-job.sh`:

```bash
#!/bin/bash
while true; do    
    # Calculate seconds until next 3:00 AM
    next_run=$(date -d "tomorrow 03:00" +%s)
    now=$(date +%s)
    sleep $((next_run - now))
    
    # Or wait for an hour
    # sleep 3600

    # Your logic here
    sh /path/to/your/my-custom-job.sh
done
```

Then create a supervisor `my-custom-job.conf` config pointing to your mounted script.
