# == Class mesos::cli
#
# Manages optional CLI packages providing e.g. command: `mesos ps`.
#
# Python 2.7 is required
# === Parameters
#
#  [*zookeeper*]
#     A zookeeper URL in format 'zk://server1:port[,server2:port]/mesos'
#
class mesos::cli(
  $debug            = false,
  $ensure           = 'present',
  $group            = $mesos::group,
  $log_file         = 'null',
  $log_level        = 'warning',
  $manage_pip       = true,
  $master           = $mesos::master,
  $max_workers      = 5,
  $owner            = $mesos::owner,
  $package_provider = undef,
  $packages         = ['mesos.cli', 'mesos.interface'],
  $pip_package      = 'python-pip',
  $response_timeout = 5,
  $scheme           = 'http',
  $zookeeper        = $mesos::zookeeper_url,
) inherits mesos {
  validate_array($packages)

  if $manage_pip {
    ensure_packages($pip_package)
    Package[$pip_package] -> Package[$packages]
  }

  if $package_provider {
    $package_provider_real = $package_provider
  } else {
    if $manage_pip {
      $package_provider_real = 'pip'
    }
  }

  $defaults = {
    'provider' => $package_provider_real,
    'ensure'   => $ensure,
  }

  ensure_packages($packages, $defaults)

  file { '/etc/.mesos.json':
    ensure  => 'present',
    content => template('mesos/mesos.json.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
  }

}
