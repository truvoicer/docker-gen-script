<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wpv6_db' );

/** Database username */
define( 'DB_USER', 'root' );

/** Database password */
define( 'DB_PASSWORD', 'password' );

/** Database hostname */
define( 'DB_HOST', 'sites_db' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'NAMC|$*;p}.3_ mq|hEyAtX5-%B[`sishHwb(G,X25S5t:9VQ+*d@xcieA+aYzy-');
define('SECURE_AUTH_KEY',  '+S+v>}Xre]Gqr;&IBg|!5J/ 5ny+2U/s[6x+L@H7[;XZP+h{cy3DEBN{OiHs@y%(');
define('LOGGED_IN_KEY',    '$;u;BSU;5LL%R-|@dZ`YUUTqlb8kgGs}Q&WU[hvy[$AzoZ4:!0ujTE9e5v+a-jbV');
define('NONCE_KEY',        '~vx|HQkL>-4x=|c%3X:oHJkm_-XWw2>J,RZ?##plp=):MUBd|%96)*-sdm*;]hhl');
define('AUTH_SALT',        '-c8Xh@0R3u;W-Mn.D=_|pq%$kq(_]u?+s!,BqFuw]=,nxUBL1g9-(|>pRQRdz)~#');
define('SECURE_AUTH_SALT', ' E(-?{;Ad@~3)hNy*j6wN|-+ S4TDY6n*EULck-^$@f3!VY$)`Bi@Jy/mU|trYp]');
define('LOGGED_IN_SALT',   'Sf]0-.y5x+Azg-qA|:<C<_sWe~r{~l(qc;uIYUj!L)Y+9TAs 4D4t)Jfbi@1dFu]');
define('NONCE_SALT',       'U3?eR3{Lj:k2IQFE,V8*CBsc)HgC!*;6q0Jc+ UlC;lK,/1#>am|+(44)CqGEl9T');

/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Add any custom values between this line and the "stop editing" line. */

define( 'WP_DEBUG_LOG', false );

// define( 'WP_ALLOW_MULTISITE', true );
// define( 'SUBDOMAIN_INSTALL', false );
// define( 'DOMAIN_CURRENT_SITE', 'localhost' );
// define( 'PATH_CURRENT_SITE', '/' );
// define( 'SITE_ID', 1 );
// define( 'BLOG_ID', 1 );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
