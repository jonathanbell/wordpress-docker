# Example: Wordpress on Docker

This is an example of Wordpress running on Docker (for local development).

- Uses Wordpress 5.2.4 (at this time)
- Uses SSL
- Has Xdebug enabled

## Installation

1. Clone this repository and `cd` into it
1. `docker-compose build`

## Connecting to the database from the host

Port 3306 is mapped to port 3307 on the host. So, you can use the following credentials:

- Host: 127.0.0.1
- Password: wordpress
- User: root
- Database: wordpress
