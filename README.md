# Overview

This **boilerplate** gives you a ready-to-use **WordPress** environment powered by Docker.
It runs **WordPress**, **MySQL**, **Nginx**, and **phpMyAdmin** - everything you need to develop and
run a **production-ready WordPress website**, all inside lightweight containers.

The setup is secured, optimized, Git-friendly, and easy to use.

# Features

- **Automated setup via init.sh**

  Automatically downloads WordPress core, creates and configure wp-config.php, and sets timezone,
  permalinks, language, and more.

  (See `init.sh` for details.)


- **Nginx + PHP-FPM**

  Fast and secure configuration optimized for WordPress performance and PHP isolation.

  (See `nginx/default.conf` for details.)


- **Persistent data & uploads**

  MySQL data and WordPress uploads are stored in Docker volumes (db_data, wp_uploads) for safe
  persistence between rebuilds.


- **phpMyAdmin included**

  Easily manage your database via a web interface.


- **Git-ready workflow**

  The WordPress core is not included in the repository, keeping it lightweight and easy to manage.
  Only your custom themes, plugins, and setup files are tracked in Git.


- **CI/CD friendly**

  Easily integrate with CI/CD pipelines for automated testing and deployment.

# WordPress Site Setup

This project uses the **docker-compose.yml** configuration provided in the repository.
It includes services for **WordPress**, **MySQL**, **phpMyAdmin** and pre-configured **WP theme**.

**Prepare Environment**

Copy environment variables from **dist.env** to **.env**

```shell
$ cp dist.env .env
```

**Install and configure WordPress**

```sh
$ docker compose run --rm -v "$(pwd)/init.sh":/var/www/html/init.sh wpcli ./init.sh
```

**Start the containers**

```sh
$ docker compose up -d
```

**Read logs**

```sh
$ docker compose logs -f
```

**Add custom hostnames (local/dev)**

Use your hosts file to map friendly domains to your **local machine**.

```txt
127.0.0.1 local.test pma.local.test
```

**Where to edit the hosts file**

Windows: _C:\Windows\System32\drivers\etc\hosts_ (open Notepad as Administrator)

macOS and Linux: _/etc/hosts_

```shell
$ sudo nano /etc/hosts
```

It's not needed in production. In DNS zone, create a record pointing to your server (e.g., an A record for
IPv4 or AAAA for IPv6). Once DNS resolves to your server, your web server will load WordPress for
that hostname.

---

Once added you can access the services via:

- WordPress : http://local.test
- phpMyAdmin: http://pma.local.test:8085

Access **_http://local.test/wp-admin/_** with:

- Username: `admin`
- Password: `admin_pass_123`

_(You can change these in the .env file. For production, make sure to use strong, unique
credentials!)_

---

# WordPress CLI Commands

Here are some helpful **WP-CLI** commands for managing and developing your WordPress site:

**List installed themes**

```sh
$ docker compose run --rm wpcli 'wp theme list'
```

**Fix file and folder permissions**

```sh
$ docker compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content/uploads
```

**Replace site domain (recommended: back up your DB first)**

```shell
$ docker compose run --rm wpcli 'wp search-replace "http://local.test" "https://example.com" --all-tables --precise'
```

**Generate translation files**

_(Adjust the paths to your plugin or theme as needed.)_

```shell
$ docker compose run --rm wpcli 'wp i18n make-mo wp-content/plugins/my-plugin/languages'
$ docker compose run --rm wpcli 'wp i18n make-json wp-content/plugins/my-plugin/languages'
```