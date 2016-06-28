# Define: mesos::node
#
# This module manages installation and initial configuration of Mesos. It's
# intended to be used as part of configuring a mesos::master or mesos::slave
# instance.
#
# Parameters: Coming soon. Maybe.
#
# Should no be called directly (outside of this package)
#
define mesos::node (
  $ensure            = 'present',
  $version           = undef,
  $repo              = undef,
  $log_dir           = undef,
  $conf_dir          = '/etc/mesos',
  $conf_file         = '/etc/default/mesos',
  $manage_zk_file    = true,
  $owner             = 'root',
  $group             = 'root',
  $manage_python     = false,
  $manage_zookeeper  = false,
  $zookeeper         = [],
  $python_package    = 'python',
  $force_provider    = undef,
  $env_var           = {},
) {
  validate_hash($env_var)
  validate_bool($manage_zk_file)
  validate_bool($manage_python)
  validate_bool($manage_zookeeper)

  if !empty($zookeeper) {
    if is_string($zookeeper) {
      warning('\$zookeeper parameter should be an array of IP addresses, please update your configuration.')
    }
    $zookeeper_url = zookeeper_servers_url($zookeeper, $zk_path, $zk_default_port)
  }

  $mesos_ensure = $version ? {
    undef    => $ensure,
    default  => $version,
  }

  class { 'mesos::install':
    ensure                  => $mesos_ensure,
    repo_source             => $repo,
    manage_python           => $manage_python,
    manage_zookeeper        => $manage_zookeeper,
    python_package          => $python_package,
    remove_package_services => $force_provider == 'none',
  }

  class { 'mesos::config':
    log_dir        => $log_dir,
    conf_dir       => $default_conf_dir,
    conf_file      => $default_conf_file,
    manage_zk_file => $manage_zk_file,
    owner          => $owner,
    group          => $group,
    zookeeper_url  => $zookeeper_url,
    env_var        => $env_var,
    ulimit         => $ulimit,
    require        => Class['mesos::install']
  }
}
