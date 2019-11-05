# Example: Wordpress on Docker

This is an example of Wordpress running on Docker (for local development).

Shiny things:

- Uses Wordpress 5.2.4 (at this time)
- Uses SSL
- Has Xdebug enabled

## Installation

1. Clone this repository and `cd` into it
1. Optional: `rm -rf ./.git`
1. `docker-compose build`
1. `docker-compose up`
1. Open <https://localhost>
1. Create a new Wordpress using these credentials:
    - Database Name: `wordpress`
    - User: `root`
    - Password: `wordpress`
    - Host: `wordpress-db`

## Connecting to the development database from the host

Port 3306 is mapped to port 3307 on the host. So, you can use the following credentials inside a Database GUI application:

- Host: `127.0.0.1`
- Port: `3307`
- User: `root`
- Password: `wordpress`
- Database: `wordpress`

## SSHing to the guest containers

Database: `docker exec -u 0 -it wordpress-db bash`

Web server: `docker exec -u 0 -it wordpress bash`

## Importing a production database for use on the local Docker container

1. It's probably best to [turn off all plugins](https://www.siteground.com/kb/how_to_disable_all_wordpress_plugins_directly_from_database/) and themes before dumping the DB
1. Dump the database on your server: `mysqldump -u root -p<root_password> <database_name> > <dumpfilename.sql>`
1. Download the dump file to `./docker/database-import/`
1. Import the dumpfile:
    1. `docker exec -u 0 -it wordpress-db bash`
    1. `cd /home`
    1. `mysql -u root -pwordpress wordpress < <dumpfilename.sql>`
1. Update the domain inside the wp database to `https://localhost`
    1. `mysql -u root -pwordpress`
    1. `USE wordpress;`
    1. `UPDATE wp_options SET option_value = replace(option_value, '<olddomain.com>', 'localhost') WHERE option_name = 'home' OR option_name = 'siteurl';`
    1. `UPDATE wp_posts SET guid = replace(guid, '<olddomain.com>', 'localhost');`
    1. `UPDATE wp_posts SET post_content = replace(post_content, '<olddomain.com>', 'localhost');`
    1. `UPDATE wp_postmeta SET meta_value = replace(meta_value, '<olddomain.com>', 'localhost');`
    1. `UPDATE wp_posts SET post_excerpt = replace(post_excerpt, '<olddomain.com>', 'localhost');`
    1. `quit`

Keep in mind that the above will only update the domain. Other settings like theme and images will need to be handled differently/separately.

You may need to reset the admin password to your site. You can do that via:

```SQL
UPDATE `wp_users` SET `user_pass` = MD5( 'new_password' ) WHERE `wp_users`.`user_login` = "admin_username";
```

## Logs

Logs such as Apache error logs can be found at: `./docker/logs`

TODO: Add the MySQL logs here too! 
