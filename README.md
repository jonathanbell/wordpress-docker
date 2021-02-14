# Wordpress on Docker

This is an example of Wordpress running on Docker (for local development).

Features:

- Wordpress 5.6.*
- Uses SSL
- PHP 8.*

## Installation

1. Clone this repository and `cd` into it
1. Optional: `rm -rf ./.git` (if you would like to use this repo as a template
   for your own Wordpress project)
1. `chmod +x ./docker-reset.sh`
1. `docker-compose up --build`
1. Open <https://localhost>
1. Create a new Wordpress site using these credentials:
    - Database Name: `wordpress`
    - User: `root`
    - Password: `wordpress`
    - Host: `wordpress-db`

## Connecting to the development database from the host

Port 3306 is mapped to port 3309 on the host. So, you can use the following
credentials inside a Database GUI application:

- Host: `127.0.0.1`
- Port: `3309`
- User: `root`
- Password: `wordpress`
- Database: `wordpress`

## SSHing to the guest containers

Application: `docker exec -u 0 -it wordpress bash`

Database: `docker exec -u 0 -it wordpress-db bash`

## Importing a production database for use on the local Docker container

Use a tool like [WP Migrate DB
Pro](https://deliciousbrains.com/wp-migrate-db-pro/) (**recommended**), or
follow these steps below to dump and import your database locally:

1. [Turn off all
   plugins](https://www.siteground.com/kb/how_to_disable_all_wordpress_plugins_directly_from_database/)
   and themes before creating your SQL dump file
1. Dump the database on your server: `mysqldump -u root -p<root_password>
   <database_name> > <dumpfilename.sql>`
1. Download the dump file to `./docker/database-import/`
1. Import the dumpfile:
    1. `docker exec -u 0 -it wordpress-db bash`
    1. `cd /home/devuser`
    1. `mysql -u root -pwordpress wordpress < <dumpfilename.sql>`
1. Update the domain inside the WP database to `https://localhost`
    1. Connect to the Docker database `mysql -u root -pwordpress` and run the
       following queries:

```sql
USE wordpress;
-- Replace `<olddomain.com>` your bare production domain. We assume your production protocol is `https://`.
UPDATE wp_options SET option_value = replace(option_value, '<olddomain.com>', 'localhost') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, '<olddomain.com>', 'localhost');
UPDATE wp_posts SET post_content = replace(post_content, '<olddomain.com>', 'localhost');
UPDATE wp_postmeta SET meta_value = replace(meta_value, '<olddomain.com>', 'localhost');
UPDATE wp_posts SET post_excerpt = replace(post_excerpt, '<olddomain.com>', 'localhost');
quit
```

Keep in mind that the above will only update the domain. Other settings like
theme and images will need to be handled differently/separately. This is why its
important to turn off themes and plugins before dumping the production database.

You may need to reset the admin password to your site. You can do that via:

```sql
UPDATE `wp_users` SET `user_pass` = MD5( 'new_password' ) WHERE `wp_users`.`user_login` = "admin_username";
```

## Logs

Logs such as Apache error logs can be found at: `./docker/logs`

## Shutdown Wordpress

The command `docker-compose down` removes the containers and default network,
but preserves your WordPress database.
