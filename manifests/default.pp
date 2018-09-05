class { 'postgresql::server':  }

class {'postgresql::server::postgis': }

postgresql::server::db { 'geodjango':
  user     => $title,
  password => $title,
}

postgresql_psql { 'Add password to role':
  db      => 'geodjango',
  command => "ALTER ROLE geodjango WITH PASSWORD 'geodjango';",
  require => Postgresql::Server::Role['geodjango'],
}

postgresql::server::role {'geodjango':;}

postgresql::server::database_grant { 'grant ALL privilleges for user geodjango':
  privilege => 'ALL',
  db        => 'geodjango',
  role      => 'geodjango',
}

postgresql_psql { 'Enable postgis extension':
  db      => 'geodjango',
  command => 'CREATE EXTENSION postgis;',
  unless  => "SELECT extname FROM pg_extension WHERE extname ='postgis'",
  require => Postgresql::Server::Db['geodjango'],
}

package {
  'binutils':  ensure                 => present;
  'libproj-dev': ensure               => present;
  'gdal-bin': ensure                  => present;
  'postgresql-server-dev-9.3': ensure => present;
  'build-essential': ensure           => latest;
  'python3': ensure                   => latest;
  'python3.4-dev': ensure             => latest;
  'python3-setuptools': ensure        => latest;
  'python3-pip': ensure               => latest;
  'python3.4-venv': ensure            => latest;
  'python-pip': ensure                => present;
}

class { 'redis':;
}

user { 'geodjango':
  ensure     => present,
  managehome => true,
}

file { ['/opt/geodjango/','/opt/geodjango/geodjango']:
  ensure => 'directory',
  owner  => 'geodjango'
}

include git

vcsrepo { '/opt/geodjango/geodjango':
  ensure   => latest,
  provider => git,
  source   => 'https://github.com/krzysztofzuraw/geodjango-leaflet.git',
  user     => 'geodjango',
  force     => true,
}

exec { 'create venv':
  command => 'python3 -m venv /opt/geodjango/env',
  path    => '/usr/local/bin:/usr/bin:/bin',
  require => Vcsrepo['/opt/geodjango/geodjango'],
}

exec { 'install requirements':
  command => '/opt/geodjango/env/bin/pip install -r /opt/geodjango/geodjango/requirements.txt',
  path    => '/usr/local/bin:/usr/bin:/bin',
  require => Exec['create venv']
}


include ::supervisord

supervisord::program { 'django':
  command     => '/opt/geodjango/env/bin/gunicorn geodjango_leaflet.wsgi -b 127.0.0.1:9000',
  user        => 'geodjango',
  directory   => '/opt/geodjango/geodjango',
  subscribe   => Vcsrepo['/opt/geodjango/geodjango'],
}

class {'nginx':
  confd_purge  => true,
  vhost_purge  => true,
}

$nginx_settings = {
  'upstream_name'    => 'geodjango',
  'upstream_address' => '127.0.0.1:9000',
}

file { ["/etc/nginx/sites-available/geodjango.conf","/etc/nginx/sites-enabled/geodjango.conf" ] :
  ensure   => file,
  content  => template('nginx.erb'),
  notify   => Service['nginx']
}